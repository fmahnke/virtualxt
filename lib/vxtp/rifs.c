/*
Copyright (c) 2019-2022 Andreas T Jonsson

This software is provided 'as-is', without any express or implied
warranty. In no event will the authors be held liable for any damages
arising from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:

1. The origin of this software must not be misrepresented; you must not
   claim that you wrote the original software. If you use this software
   in a product, an acknowledgment in the product documentation would be
   appreciated but is not required.
2. Altered source versions must be plainly marked as such, and must not be
   misrepresented as being the original software.
3. This notice may not be removed or altered from any source distribution.
*/

#include "vxtp.h"
#include "crc32.h"

#include <assert.h>
#include <string.h>
#include <stdio.h>

#define BUFFER_SIZE 1024
#define MAX_PATH_LEN 1024
#define MAX_DOS_PROC 256
#define MAX_OPEN_FILES 256

VXT_PACK(struct rifs_packet {
    vxt_byte packetID[2];   // 'K', 'Y': Request from server.
                            // 'L', 'Y': Reply from server.
                            // 'R', 'P': Resent last packet, either direction.

    vxt_word length;        // Total number of bytes in this block, incl header.
    vxt_word notlength;     // ~Length (used for checking).
    vxt_word cmd;           // Command to execute / result.
    vxt_word _;             // Machine ID of block sender. NOT USED!
    vxt_word __;            // Machine ID of intended reciever. NOT USED!
    vxt_word process_id;    // ID of sending process. (for closeall)
    vxt_dword crc32;        // CRC-32 of entire block. (calculated with crc32 set to zero)
    vxt_byte data[];        // Payload data.
});

enum {
    IFS_RMDIR,
    IFS_MKDIR,
    IFS_CHDIR,
    IFS_CLOSEFILE,
    IFS_COMMITFILE,
    IFS_READFILE,
    IFS_WRITEFILE,
    IFS_LOCKFILE,
    IFS_UNLOCKFILE,
    IFS_GETSPACE,
    IFS_SETATTR,
    IFS_GETATTR,
    IFS_RENAMEFILE,
    IFS_DELETEFILE,
    IFS_OPENFILE,
    IFS_CREATEFILE,
    IFS_FINDFIRST,
    IFS_FINDNEXT,
    IFS_CLOSEALL,
    IFS_EXTOPEN
};

struct dos_proc {
    bool active;
    vxt_word id;
    FILE *files[MAX_OPEN_FILES];
};

#ifdef __linux__
    #include "rifs_unix.h"
#else
    #include "rifs_dummy.h"
#endif

VXT_PIREPHERAL(rifs, {
    vxt_word base_port;
    vxt_byte registers[8];
    bool dlab;

    vxt_byte buffer_input[BUFFER_SIZE];
    int buffer_input_len;

    vxt_byte buffer_output[BUFFER_SIZE];
    int buffer_output_len;

    char path_scratchpad[MAX_PATH_LEN];
    struct dos_proc processes[MAX_DOS_PROC];
})

// Expects the 'cmd' and 'process_id' to be set by caller.
static void server_response(struct rifs *fs, const struct rifs_packet *pk, int payload_size) {
    assert(!fs->buffer_input_len);

    int size = payload_size + sizeof(struct rifs_packet);
    assert(size <= BUFFER_SIZE);
    fs->buffer_input_len = size;

    struct rifs_packet *dest = (struct rifs_packet*)fs->buffer_input;
    memcpy(dest, pk, size);
    dest->length = (vxt_word)size;
    dest->notlength = ~dest->length;

    dest->packetID[0] = 'L'; dest->packetID[1] = 'Y';

    dest->crc32 = 0;
    dest->crc32 = crc32(fs->buffer_input, dest->length);
}

static bool verify_packet(struct rifs_packet *pk) {
    vxt_word len = ~pk->notlength;
    if (pk->length != len) {
        fprintf(stderr, "RIFS packet of invalid size!\n");
        return false;
    }

    vxt_dword crc = pk->crc32;
    pk->crc32 = 0;

    if (crc != crc32((vxt_byte*)pk, len)) {
        fprintf(stderr, "RIFS packet CRC failed!\n");
        return false;
    }

    pk->crc32 = crc; // Restore the CRC if needed later.
    return true;
}

static const char *host_path(struct rifs *fs, const char *path) {
    strcpy(fs->path_scratchpad, "/home/phix/dos_tmp/"); // Host root path.

    // Remove drive letter.
    if ((strlen(path) >= 2) && (path[1] == ':'))
        path = path + 2;
    else
        fprintf(stderr, "RIFS path is not absolute!\n");
       
    strncat(fs->path_scratchpad, path, sizeof(fs->path_scratchpad));

    // Convert slashes.
    int ln = strlen(fs->path_scratchpad);
    for (int i = 0; i < ln; i++) {
        if (fs->path_scratchpad[i] == '\\')
            fs->path_scratchpad[i] = '/';
    }
    return fs->path_scratchpad;
}

static struct dos_proc *get_proc(struct rifs *fs, vxt_word id) {
    struct dos_proc *inactive = NULL;
    for (int i = 0; i < MAX_DOS_PROC; i++) {
        struct dos_proc *proc = &fs->processes[i];
        if (!inactive && !proc->active)
            inactive = proc;
        if (proc->id == id && proc->active)
            return proc;
    }

    // Create new proc.
    inactive->id = id;
    inactive->active = true;
    memset(inactive->files, 0, sizeof(inactive->files));
    return inactive;
}

static void process_request(struct rifs *fs, struct rifs_packet *pk) {
    int data_size = pk->length - sizeof(struct rifs_packet);
    struct dos_proc *proc = get_proc(fs, pk->process_id);
    if (!proc) {
        fprintf(stderr, "To many RIFS procs!\n");
        return;
    }

    switch (pk->cmd) {
        case IFS_RMDIR:
            pk->cmd = rifs_rmdir(host_path(fs, (char*)pk->data));
            server_response(fs, pk, 0);
            break;
        case IFS_MKDIR:
            pk->cmd = rifs_mkdir(host_path(fs, (char*)pk->data));
            server_response(fs, pk, 0);
            break;
        //case IFS_CLOSEFILE:
        //    break;
        //case IFS_READFILE:
        //    break;
        //case IFS_WRITEFILE:
        //    break;
        //case IFS_LOCKFILE:
        //    break;
        //case IFS_UNLOCKFILE:
        //    break;
        //case IFS_GETSPACE:
        //    break;
        //case IFS_SETATTR:
        //    break;
        //case IFS_GETATTR:
        //    break;
        case IFS_RENAMEFILE:
        {
            const char *new_name = (char*)pk->data + strlen((char*)pk->data) + 1;
            pk->cmd = rifs_rename(host_path(fs, (char*)pk->data), new_name);
            server_response(fs, pk, 0);
            break;
        }
        case IFS_DELETEFILE:
            pk->cmd = rifs_delete(host_path(fs, (char*)pk->data));
            server_response(fs, pk, 0);
            break;
        case IFS_OPENFILE:
            pk->cmd = 3;//rifs_openfile(proc, *(vxt_word*)pk->data, host_path(fs, (char*)pk->data + 2), pk->data);
            server_response(fs, pk, pk->cmd ? 0 : 12);
            break;
        //case IFS_CREATEFILE:
        //    break;
        case IFS_FINDFIRST:
            printf("Find first: %s\n", pk->data+2);
            break;
        case IFS_CLOSEALL:
            for (int i = 0; i < MAX_DOS_PROC; i++) {
                if (proc->id == fs->processes[i].id) {
                    proc->active = false;
                    for (int j = 0; j < MAX_OPEN_FILES; j++) {
                        FILE **fp = &proc->files[j];
                        if (*fp) {
                            fclose(*fp);
                            *fp = NULL;
                        }
                    }
                    break;
                }
            }
            pk->cmd = 0;
            server_response(fs, pk, 0);
            break;
        //case IFS_EXTOPEN:
        //    break;
        case IFS_CHDIR:
        case IFS_COMMITFILE:
            pk->cmd = 0;
            server_response(fs, pk, 0);
            break;
        default:
            fprintf(stderr, "Unknown RIFS command: 0x%X (payload size %d)\n", pk->cmd, data_size);
    }
}

static vxt_byte pop_data(struct vxt_pirepheral *p) {
    VXT_DEC_DEVICE(fs, rifs, p);
    assert(fs->buffer_input_len > 0);
    vxt_byte data = *fs->buffer_input;
    memmove(fs->buffer_input, &fs->buffer_input[1], --fs->buffer_input_len);
    return data;
}

static vxt_byte in(struct vxt_pirepheral *p, vxt_word port) {
    VXT_DEC_DEVICE(fs, rifs, p);
	vxt_word reg = port & 7;
	switch (reg) {
        case 0: // Serial Data Register
            if (fs->dlab)
                return fs->registers[reg];
            return fs->buffer_input_len ? pop_data(p) : 0;
        case 5: // Line Status Register
        {
            vxt_byte res = 0x60; // Always assume transmition buffer is empty.
            if (fs->buffer_input_len)
                res |= 1;
            return res;
        }
	}
	return fs->registers[reg];
}

static void out(struct vxt_pirepheral *p, vxt_word port, vxt_byte data) {
    VXT_DEC_DEVICE(fs, rifs, p);
	vxt_word reg = port & 7;
	fs->registers[reg] = data;

	switch (reg) {
        case 0: // Serial Data Register
            if (fs->dlab)
                return;

            if (fs->buffer_output_len >= BUFFER_SIZE) {
                fprintf(stderr, "Invalid RIFS buffer state!\n");
                fs->buffer_output_len = 0;
                return;
            }

            fs->buffer_output[fs->buffer_output_len++] = data;
            if (fs->buffer_output_len >= (int)sizeof(struct rifs_packet)) {
                struct rifs_packet *p = (struct rifs_packet*)fs->buffer_output;
                if (p->length == fs->buffer_output_len) { // Is packet ready?
                    fs->buffer_output_len = 0;
                    if (verify_packet(p))
                        process_request(fs, p);
                }
            }
            break;
        case 3: // Line Control Register
            {
                bool dlab = data & 0x80;
                if (fs->dlab != dlab) {
                    fs->dlab = dlab;
                    fs->buffer_output_len = fs->buffer_input_len = 0;
                    fprintf(stderr, "DLAB change! Assume RIFS state reset.\n");
                }
            }
            break;
    }
}

static vxt_error install(vxt_system *s, struct vxt_pirepheral *p) {
    VXT_DEC_DEVICE(fs, rifs, p);
    vxt_system_install_io(s, p, fs->base_port, fs->base_port + 7);
    return VXT_NO_ERROR;
}

static vxt_error destroy(struct vxt_pirepheral *p) {
    vxt_system_allocator(VXT_GET_SYSTEM(rifs, p))(p, 0);
    return VXT_NO_ERROR;
}

static vxt_error reset(struct vxt_pirepheral *p) {
    VXT_DEC_DEVICE(fs, rifs, p);
    vxt_memclear(fs->registers, sizeof(fs->registers));
    return VXT_NO_ERROR;
}

static const char *name(struct vxt_pirepheral *p) {
    (void)p;
    return "RIFS Server";
}

struct vxt_pirepheral *vxtp_rifs_create(vxt_allocator *alloc, vxt_word base_port) {
    struct vxt_pirepheral *p = (struct vxt_pirepheral*)alloc(NULL, VXT_PIREPHERAL_SIZE(rifs));
    vxt_memclear(p, VXT_PIREPHERAL_SIZE(rifs));
    VXT_DEC_DEVICE(fs, rifs, p);

    fs->base_port = base_port;

    p->install = &install;
    p->destroy = &destroy;
    p->name = &name;
    p->reset = &reset;
    p->io.in = &in;
    p->io.out = &out;
    return p;
}

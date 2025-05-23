% PT_EVT_SYNC_FORWARD(3)

<!---
 ! Copyright (C) 2015-2025 Intel Corporation
 ! SPDX-License-Identifier: BSD-3-Clause
 !
 ! Redistribution and use in source and binary forms, with or without
 ! modification, are permitted provided that the following conditions are met:
 !
 !  * Redistributions of source code must retain the above copyright notice,
 !    this list of conditions and the following disclaimer.
 !  * Redistributions in binary form must reproduce the above copyright notice,
 !    this list of conditions and the following disclaimer in the documentation
 !    and/or other materials provided with the distribution.
 !  * Neither the name of Intel Corporation nor the names of its contributors
 !    may be used to endorse or promote products derived from this software
 !    without specific prior written permission.
 !
 ! THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 ! AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 ! IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ! ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 ! LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 ! CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 ! SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 ! INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 ! CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 ! ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 ! POSSIBILITY OF SUCH DAMAGE.
 !-->

# NAME

pt_evt_sync_forward, pt_evt_sync_backward, pt_evt_sync_set - synchronize an
Intel(R) Processor Trace event decoder


# SYNOPSIS

| **\#include `<intel-pt.h>`**
|
| **int pt_evt_sync_forward(struct pt_event_decoder \**decoder*);**
| **int pt_evt_sync_backward(struct pt_event_decoder \**decoder*);**
| **int pt_evt_sync_set(struct pt_event_decoder \**decoder*,**
|                     **uint64_t *offset*);**

Link with *-lipt*.


# DESCRIPTION

These functions synchronize an Intel Processor Trace (Intel PT) event decoder
pointed to by *decoder* onto the trace stream in *decoder*'s trace buffer.

They search for a Packet Stream Boundary (PSB) packet in the trace stream and,
if successful, set *decoder*'s current position and synchronization position to
that packet and start processing packets.  For synchronization to be
successful, there must be a full PSB+ header in the trace stream.

**pt_evt_sync_forward**() searches in forward direction from *decoder*'s current
position towards the end of the trace buffer.  If *decoder* has been newly
allocated and has not been synchronized yet, the search starts from the
beginning of the trace.

**pt_evt_sync_backward**() searches in backward direction from *decoder*'s
current position towards the beginning of the trace buffer.  If *decoder* has
been newly allocated and has not been synchronized yet, the search starts from
the end of the trace.

**pt_evt_sync_set**() searches at *offset* bytes from the beginning of its trace
buffer.


# RETURN VALUE

All synchronization functions return zero or a positive value on success or a
negative *pt_error_code* enumeration constant in case of an error.


# ERRORS

pte_invalid
:   The *decoder* argument is NULL.

pte_eos
:   There is no (further) PSB+ header in the trace stream
    (**pt_evt_sync_forward**() and **pt_evt_sync_backward**()) or at *offset*
    bytes into the trace buffer (**pt_evt_sync_set**()).

pte_nosync
:   There is no PSB packet at *offset* bytes from the beginning of the trace
    (**pt_evt_sync_set**() only).

pte_bad_opc
:   The decoder encountered an unsupported Intel PT packet opcode.

pte_bad_packet
:   The decoder encountered an unsupported Intel PT packet payload.


# EXAMPLE

The following example re-synchronizes an Intel PT event decoder after decode
errors:

~~~{.c}
int foo(struct pt_event_decoder *decoder) {
	for (;;) {
		int errcode;

		errcode = pt_evt_sync_forward(decoder);
		if (errcode < 0)
			return errcode;

		do {
			errcode = decode(decoder);
		} while (errcode >= 0);
	}
}
~~~


# SEE ALSO

**pt_evt_alloc_decoder**(3), **pt_evt_free_decoder**(3),
**pt_evt_get_offset**(3), **pt_evt_get_sync_offset**(3),
**pt_evt_get_config**(3), **pt_evt_next**(3)
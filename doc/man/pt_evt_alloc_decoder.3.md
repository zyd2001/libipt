% PT_EVT_ALLOC_DECODER(3)

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

pt_evt_alloc_decoder, pt_evt_free_decoder - allocate/free an Intel(R) Processor
Trace event decoder


# SYNOPSIS

| **\#include `<intel-pt.h>`**
|
| **struct pt_event_decoder \***
| **pt_evt_alloc_decoder(const struct pt_config \**config*);**
|
| **void pt_evt_free_decoder(struct pt_event_decoder \**decoder*);**

Link with *-lipt*.


# DESCRIPTION

A event decoder decodes raw Intel Processor Trace (Intel PT) and combines Intel
PT packets into a stream of Intel PT events.

This information can be used to reconstruct the execution flow of the traced
code.  Decode instructions until the next event, then apply the event.

**pt_evt_alloc_decoder**() allocates a new event decoder and returns a pointer
to it.  The *config* argument points to a *pt_config* object.  See
**pt_config**(3).  The *config* argument will not be referenced by the returned
decoder but the trace buffer defined by the *config* argument's *begin* and
*end* fields will.

The returned event decoder needs to be synchronized onto the trace stream before
it can be used.  To synchronize the event decoder, use
**pt_evt_sync_forward**(3), **pt_evt_sync_backward**(3), or
**pt_evt_sync_set**(3).

**pt_evt_free_decoder**() frees the Intel PT event decoder pointed to by
*decoder*.  The *decoder* argument must be NULL or point to a decoder that has
been allocated by a call to **pt_evt_alloc_decoder**().


# RETURN VALUE

**pt_evt_alloc_decoder**() returns a pointer to a *pt_event_decoder* object on
success or NULL in case of an error.


# EXAMPLE

~~~{.c}
int foo(const struct pt_config *config) {
	struct pt_event_decoder *decoder;
	errcode;

	decoder = pt_evt_alloc_decoder(config);
	if (!decoder)
		return -pte_nomem;

	errcode = bar(decoder);

	pt_evt_free_decoder(decoder);
	return errcode;
}
~~~


# SEE ALSO

**pt_config**(3), **pt_evt_sync_forward**(3), **pt_evt_sync_backward**(3),
**pt_evt_sync_set**(3), **pt_evt_get_offset**(3), **pt_evt_get_sync_offset**(3),
**pt_evt_get_config**(3), **pt_evt_next**(3)

#!/usr/sbin/dtrace -s

#pragma D option switchrate=1000hz
#pragma D option bufsize=128m

BEGIN {
	in_vertblock = 0;
	ignoring = 0;
}

pid$target:libGL.dylib:glGenBuffersARB:entry {
	self->n = arg0;
	self->ids = arg1;
}

pid$target:libGL.dylib:glGenBuffersARB:return {
	printf("%i", *(uint32_t *) copyin(self->ids, 4));
}

pid$target:libGL.dylib:glBindBufferARB:entry /arg1 > 0/ {
	printf("%i %i", arg1, arg0);
}

pid$target:libGL.dylib:glBufferDataARB:entry /arg1 > 0 && arg1 <= 1024/ {
	printf("%i %i %i", arg1, arg0, arg3);
	tracemem(copyin(arg2, arg1), 1024, arg1);
}
pid$target:libGL.dylib:glBufferDataARB:entry /arg1 > 1024 && arg1 <= 16384/ {
	printf("%i %i %i", arg1, arg0, arg3);
	tracemem(copyin(arg2, arg1), 16384, arg1);
}
pid$target:libGL.dylib:glBufferDataARB:entry /arg1 > 16384 && arg1 <= 32768/ {
	printf("%i %i %i", arg1, arg0, arg3);
	tracemem(copyin(arg2, arg1), 32768, arg1);
}
pid$target:libGL.dylib:glBufferDataARB:entry /arg1 > 32768 && arg1 <= 49152/ {
	printf("%i %i %i", arg1, arg0, arg3);
	tracemem(copyin(arg2, arg1), 49152, arg1);
}
pid$target:libGL.dylib:glBufferDataARB:entry /arg1 > 49152 && arg1 <= 131072/ {
	printf("%i %i %i", arg1, arg0, arg3);
	tracemem(copyin(arg2, arg1), 131072, arg1);
}
pid$target:libGL.dylib:glBufferDataARB:entry /arg1 > 131072 && arg1 <= 1048576/ {
	printf("%i %i %i", arg1, arg0, arg3);
	tracemem(copyin(arg2, arg1), 1048576, arg1);
}
pid$target:libGL.dylib:glBufferDataARB:entry /arg1 > 1048576/ {
	printf("MELTDOWN");
	exit(0);
}

pid$target:GLEngine:glBegin_Exec:entry /ignoring != 1/ {
	in_vertblock = 1;
	printf("%i", arg1);
}
pid$target:GLEngine:glVertex3f_Exec:entry /in_vertblock == 1 && ignoring != 1/ {
	printf("%u %u %u", arg1, arg2, arg4);
}
pid$target:GLEngine:glVertex2f_Exec:entry /in_vertblock == 1 && ignoring != 1/ {
	printf("%u %u %u", arg1, arg2, 0);
}
pid$target:GLEngine:glVertex3fv_Exec:entry /in_vertblock == 1 && ignoring != 1/ {
	vert = (uint32_t *) copyin(arg1, 12);
	printf("%u %u %u", vert[0], vert[1], vert[2]);
}
pid$target:GLEngine:glNormal3f_Exec:entry /in_vertblock == 1 && ignoring != 1/ {
	printf("%u %u %u", arg1, arg2, arg4);
}
pid$target:GLEngine:glNormal3fv_Exec:entry /in_vertblock == 1 && ignoring != 1/ {
	vert = (uint32_t *) copyin(arg1, 12);
	printf("%u %u %u", vert[0], vert[1], vert[2]);
}
pid$target:GLEngine:gleCallList:entry {
	ignoring = 1;
}
pid$target:GLEngine:gleCallList:return {
	ignoring = 0;
}
/*pid$target:GLEngine:glVertex3_ListExec:entry /in_vertblock == 1/ {
	printf("%i", arg0);
}*/
pid$target:GLEngine:glEnd_Exec:entry /in_vertblock == 1 && ignoring != 1/ {
	in_vertblock = 0;
	printf("0");
}
/*pid$target:GLEngine:gl*Normal*:entry /probefunc != "glNormal3f_Exec" && probefunc != "glNormal3fv_Exec" && in_vertblock == 1/ {
	printf("%x %x %x %x", arg0, arg1, arg2, arg3);
}*/

pid$target:GLEngine:glDrawElements_Exec:entry {
	printf("%i %i %i %i", arg1, arg2, arg3, arg4);
}

pid$target:EModelViewFW:*FinishedLoadingFile*:entry {
	exit(0);
}

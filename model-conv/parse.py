import md5, struct

enums = {
	0x8892: 'GL_ARRAY_BUFFER_ARB', 
	0x8893: 'GL_ELEMENT_ARRAY_BUFFER_ARB', 
	0x8894: 'GL_ARRAY_BUFFER_BINDING_ARB', 
	0x8895: 'GL_ELEMENT_ARRAY_BUFFER_BINDING_ARB', 
	0x88E0: 'GL_STREAM_DRAW', 
	0x88E1: 'GL_STREAM_READ', 
	0x88E2: 'GL_STREAM_COPY', 
	0x88E4: 'GL_STATIC_DRAW', 
	0x88E5: 'GL_STATIC_READ', 
	0x88E6: 'GL_STATIC_COPY', 
	0x88E8: 'GL_DYNAMIC_DRAW', 
	0x88E9: 'GL_DYNAMIC_READ', 
	0x88EA: 'GL_DYNAMIC_COPY', 
	0x1401: 'GL_UNSIGNED_BYTE', 
	0x1402: 'GL_SHORT', 
	0x1403: 'GL_UNSIGNED_SHORT', 
	0x1404: 'GL_INT', 
	0x1405: 'GL_UNSIGNED_INT', 
	0x1406: 'GL_FLOAT', 
	0x0000: 'GL_POINTS', 
	0x0001: 'GL_LINES', 
	0x0002: 'GL_LINE_LOOP', 
	0x0003: 'GL_LINE_STRIP', 
	0x0004: 'GL_TRIANGLES', 
	0x0005: 'GL_TRIANGLE_STRIP', 
	0x0006: 'GL_TRIANGLE_FAN', 
	0x0007: 'GL_QUADS', 
	0x0008: 'GL_QUAD_STRIP', 
	0x0009: 'GL_POLYGON', 
}

def enum(en):
	if en in enums:
		return enums[en]
	else:
		return 'Unknown_%x' % en

def convert(infile, outfile):
	buffers = {}
	active_buffer = 0
	active_indices = 0
	active_vertices = 0

	all_vertices = []
	all_normals = []
	ptr = 0
	all_indices = []

	pairs = []

	lines = [line.strip() for line in file(infile, 'r').read().split('\n')[1:]]
	i = 0
	while i < len(lines):
		line = lines[i]
		if line == '' or '::' in line:
			i += 1
			continue
		func, rest = line.rsplit('  ', 1)[1].split(':')
		rest = map(int, rest.split(' ')[1:])
		if func == 'glGenBuffersARB':
			buffers[rest[0]] = [None, None, None]
			i += 1
		elif func == 'glBindBufferARB':
			if rest[0] != 0:
				buffers[rest[0]][0] = enum(rest[1])
			if enum(rest[1]) == 'GL_ELEMENT_ARRAY_BUFFER_ARB':
				active_indices = rest[0]
			else:
				active_vertices = rest[0]
			active_buffer = rest[0]
			i += 1
		elif func == 'glBufferDataARB':
			i += 1
			assert lines[i] == '0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f  0123456789abcdef'
			databuf = []
			while lines[i] != '':
				i += 1
				line = [x for x in lines[i].split(' ', 17)[1:-1] if x != '']
				databuf += map(lambda x: int(x, 16), line)
			i += 1
			if rest[0] == 0:
				continue
			databuf = databuf[:rest[0]]
			buffers[active_buffer][2] = databuf
			assert buffers[active_buffer][0] == enum(rest[1])
			buffers[active_buffer][1] = enum(rest[2])
		elif func == 'glDrawElements_Exec':
			if rest[3] != 0:
				i += 1
				continue
			if enum(rest[0]) != 'GL_TRIANGLES':
				raise Exception(enum(rest[0]))
			
			buf = ''.join(map(chr, buffers[active_vertices][2]))
			data = struct.unpack('f' * (len(buf) >> 2), buf)
			ibuf = ''.join(map(chr, buffers[active_indices][2]))

			hash = md5.new(buf + ibuf).hexdigest()
			if hash not in pairs:
				pairs.append(hash)

				ptr = len(all_vertices)
				if len(data) % 6 != 0:
					print len(data), len(data) % 6
				for j in xrange(0, len(data), 6):
					all_vertices.append(data[j:j+3])
					all_normals.append(data[j+3:j+6])

				datatype = enum(rest[2])
				if datatype == 'GL_UNSIGNED_SHORT':
					data = struct.unpack('H' * (len(ibuf) >> 1), ibuf)
				else:
					raise Exception('adspfoj', datatype)

				all_indices += [ptr + x for x in data]

			i += 1
		else:
			print 'Unknown line:', line
			break

	with file(outfile, 'wb') as output:
		output.write(struct.pack('II', len(all_indices), len(all_vertices)))
		for vec in all_vertices:
			output.write(struct.pack('fff', *vec))
		for vec in all_normals:
			output.write(struct.pack('fff', *vec))
		for index in all_indices:
			output.write(struct.pack('I', index))

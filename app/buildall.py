import glob, json
from PIL import Image, ImageFilter, ImageFont, ImageDraw

def getsize(font, text):
	lines = text.split('\n')
	size = [0, 0]
	for line in lines:
		tsize = font.getsize(line)
		size[0] = max(size[0], tsize[0])
		size[1] += tsize[1]
	return size

lum = lambda x: (0.2126*x[0] + 0.7152*x[1] + 0.0722*x[2]) if not isinstance(x, int) else x

def find_lightest(im, x, y):
	pixels = []
	for xo in xrange(-5, 6):
		for yo in xrange(-5, 6):
			color = im.getpixel((x+xo, y+yo))
			pixels.append(color)
	pixels.sort()
	return pixels[-1]#[len(pixels)/2]

files = [fn.split('/')[-1].split('.')[0] for fn in glob.glob('curta_jpegs/*.jpg')]

for fn in files:
	try:
		regions = json.load(file('regions/%s.json' % fn))
		status = file('status/%s.txt' % fn).read()
	except:
		continue
	if status != 'Finished':
		continue
	print 'Processing', fn
	im = Image.open('curta_jpegs/%s.jpg' % fn)
	#bim = im.filter(ImageFilter.GaussianBlur(50))

	draw = ImageDraw.Draw(im)
	for x, y, w, h, detext, entext in regions:
		x, y, w, h = map(int, [x, y, w, h])
		color = find_lightest(im, x, y)
		if entext != '':
			if h > w:
				vertical = True
				h, w = w, h
			else:
				vertical = False
			pt = 1
			while True:
				font = ImageFont.truetype('gillsans-light.ttf', pt)
				size = getsize(font, entext)
				if size[0] > w or size[1] > h:
					pt -= 1
					break
				pt += 1
			font = ImageFont.truetype('gillsans-light.ttf', pt)
			size = getsize(font, entext)
			entext = entext.replace(u'\u03bc', u'\xb5')
			if vertical:
				draw.rectangle([x, y, x+max(h, size[1]), y+max(w, size[0])], fill=color)
				tim = Image.new('RGBA', (size[0], size[1]*2))
				tdraw = ImageDraw.Draw(tim)
				tdraw.text((0, 0), entext, font=font, fill='black')
				tim = tim.rotate(90, expand=True)
				im.paste(tim, (x, y), tim)
			else:
				draw.rectangle([x, y, x+max(w, size[0]), y+max(h, size[1])], fill=color)
				draw.text((x, y), entext, font=font, fill='black')
		else:
			draw.rectangle([x, y, x+w, y+h], fill=color)
	
	im.save('completed/%s.jpg' % fn)

from xmlrpclib import ServerProxy
from os.path import isfile
wikidoturl = file('wikidoturl', 'r').read()
s = ServerProxy(wikidoturl)
import time
import yaml

references = yaml.load(file('crossref.yaml'))
referenced = dict()
for parent, children in references.items():
	for child in children:
		if child not in referenced:
			referenced[child] = []
		if parent not in referenced[child]:
			referenced[child].append(parent)

bom = []
names = dict()

main_page = """The table below includes every part in the Curta type I.  The original engineering diagrams included on most of these pages are from the [http://www.museummura.li/content.aspx?nid=5051&groupnr=5051 Museum Mura]

||~ Part No. ||~ Name ||~ Quantity ||~ Proposed Process ||~ Has Model ||
"""

processes = dict(
	M='CNC Milled', 
	L='CNC Lathed', 
	C='Lasercut'
)

for line in file('bom.txt'):
	num, name, quantity, process = [x.strip() for x in line.split('||')][1:-1]
	num = int(num.split(' ')[0][3:-3])
	if process in processes:
		process = processes[process]
	bom.append((num, name, int(quantity), process))
	names[num] = name

for num, name, quantity, process in bom:
	time.sleep(.25)
	print 'Creating', num

	body = '[[image Curta_1_%i.jpg size="medium"]]\n' % num
	cfn = '/home/daeken/curta/app/completed/Curta_1_%i.jpg' % num
	if isfile(cfn):
		body += '[[image Curta_1_%i_en.jpg size="medium"]]\n\n' % num
	else:
		body += '\n'
	if isfile('STL Models/%i.stl' % num):
		body += '[[iframe http://demoseen.com/curta-stl/?%i width="500" height="500" ]]\n\n' % num
		main_page += '|| [[[%i]]] || %s || %i || %s || Yes ||\n' % (num, name, quantity, process)
	else:
		main_page += '|| [[[%i]]] || %s || %i || %s || ||\n' % (num, name, quantity, process)
	if num in referenced:
		body += '**Referenced by**:\n'
		for elem in referenced[num]:
			body += '* [[[%i]]] -- %s\n' % (elem, names[elem] if elem in names else 'Unknown part')
		body += '\n'
	if num in references:
		cref = []
		body += '**References**:\n'
		for elem in references[num]:
			if elem not in cref:
				cref.append(elem)
				body += '* [[[%i]]] -- %s\n' % (elem, names[elem] if elem in names else 'Unknown part')
		body += '\n'
	
	s.pages.save_one(dict(
		site='curtawiki', page=str(num), 
		title='%i -- %s' % (num, name.lstrip('!')), 
		content=body, 
		save_mode='create_or_update'
	))

	bfn = 'Curta_1_%i.jpg' % num
	benfn = 'Curta_1_%i_en.jpg' % num
	fn = '/home/daeken/demoseen/curta/Curta_1_%i.jpg' % num
	cfiles = s.files.select(dict(site='curtawiki', page=str(num)))
	if isfile(fn) and bfn not in cfiles:
		time.sleep(1)
		print 'Uploading', bfn
		data = file(fn, 'rb').read()
		s.files.save_one(dict(
			site='curtawiki', page=str(num), 
			file=bfn,
			content=data.encode('base64').replace('\n', ''), 
			save_mode='create', 
		))
	if isfile(cfn) and benfn not in cfiles:
		time.sleep(1)
		print 'Uploading', benfn
		data = file(cfn, 'rb').read()
		s.files.save_one(dict(
			site='curtawiki', page=str(num), 
			file=benfn,
			content=data.encode('base64').replace('\n', ''), 
			save_mode='create', 
		))

s.pages.save_one(dict(
	site='curtawiki', page='Parts', 
	title='Parts', 
	content=main_page, 
	save_mode='create_or_update'
))

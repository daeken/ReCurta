import glob, json
from handler import *

def load_bom():
	names = dict()
	for line in file('../bom.txt'):
		num, name, quantity, process = [x.strip() for x in line.split('||')][1:-1]
		num = int(num.split(' ')[0][3:-3])
		names[num] = name
	return names

def load_regions(fn):
	try:
		fp = file('regions/%s.json' % fn)
		return fp.read()
	except:
		return '[]'

def get_status(fn):
	try:
		fp = file('status/%s.txt' % fn)
		return fp.read()
	except:
		return None

@handler('index')
def get_index():
	files = [fn.split('/')[-1].split('.')[0] for fn in glob.glob('curta_jpegs/*.jpg')]
	not_started = []
	started = []
	needs_trans = []
	needs_review = []
	finished = []
	names = load_bom()
	for fn in files:
		num = fn.split('_')[2]
		regions = json.loads(load_regions(fn))
		status = get_status(fn)
		unfin = sum(1 for (_, __, ___, ____, detext, entext) in regions if detext.startswith('!!'))
		if status == 'In Progress' or (len(regions) > 0 and status is None):
			started.append((fn, num, names[int(num)], '%i/%i' % (len(regions) - unfin, len(regions))))
		elif status == 'Not Started' or status is None:
			not_started.append((fn, num, names[int(num)]))
		elif status == 'Needs Translation':
			needs_trans.append((fn, num, names[int(num)], '%i/%i' % (len(regions) - unfin, len(regions))))
		elif status == 'Needs Review':
			needs_review.append((fn, num, names[int(num)], '%i/%i' % (len(regions) - unfin, len(regions))))
		else:
			finished.append((fn, num, names[int(num)], '%i/%i' % (len(regions), len(regions))))
	total = len(files)
	return dict(
		not_started=(not_started, '%i/%i' % (len(not_started), total)), 
		started=(started, '%i/%i' % (len(started), total)), 
		needs_trans=(needs_trans, '%i/%i' % (len(needs_trans), total)), 
		needs_review=(needs_review, '%i/%i' % (len(needs_review), total)), 
		finished=(finished, '%i/%i' % (len(finished), total))
	)

@handler('edit')
def get_edit(fn, name):
	return dict(
		img=fn, 
		name=name, 
		status=get_status(fn), 
		regions=load_regions(fn), 
	)

@handler('view')
def get_view(fn):
	return dict(
		img=fn, 
		regions=load_regions(fn), 
	)

@handler
def get_images(fn):
	if '/' not in fn and '\\' not in fn:
		request._headers = {'Content-Type' : 'image/jpeg'}
		return file('curta_jpegs/%s.jpg' % fn).read()

@handler
def rpc_save(fn, regions):
	if '/' not in fn and '\\' not in fn:
		file('regions/%s.json' % fn, 'w').write(json.dumps(regions))

@handler
def rpc_set_status(fn, status):
	if '/' not in fn and '\\' not in fn:
		file('status/%s.txt' % fn, 'w').write(status)

@handler('fails')
def get_fails():
	files = [fn.split('/')[-1].split('.')[0] for fn in glob.glob('curta_jpegs/*.jpg')]
	fails = {}
	names = load_bom()
	for fn in files:
		num = fn.split('_')[2]
		regions = json.loads(load_regions(fn))
		for x, y, w, h, detext, entext in regions:
			if detext.startswith('!!'):
				phrase = detext[2:]
				if phrase not in fails:
					fails[phrase] = []
				fails[phrase].append((fn, num, names[int(num)], entext))
	ordered = []

	keys = sorted(fails.keys())

	return dict(
		fails=[(key, fails[key]) for key in keys]
	)

@handler('part-tag')
def get_part_tag(fn):
	names = load_bom()
	return dict(
		fn=fn, 
		parts=names.items()
	)

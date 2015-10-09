api_key = 'AIzaSyAYwphfGLaemyyc6wnkJvnXdKvNJ1YSIVM'

window.translateText = (resp) ->
	$('#en-text').val resp.data.translations[0].translatedText

translate = (text) ->
	scr = document.createElement 'script'
	scr.type = 'text/javascript'
	etext = escape(text.replace(/[\u00A0-\u9999<>\&]/gim, (i) -> '&#'+i.charCodeAt(0)+';'))
	scr.src = 'https://www.googleapis.com/language/translate/v2?key=' + api_key + '&source=de&target=en&callback=translateText&format=html&q=' + etext
	document.getElementsByTagName('head')[0].appendChild scr

cvsh = null
currentRegion = -1
newRegion = 0
newRegionPos = false
reshaping = 0
showEnglish = false

class CanvasHelper
	constructor: ->
		@cvs = $('#cvs')[0]
		@cvs.width = @cvs.clientWidth
		@cvs.height = @cvs.clientHeight
		$(window).resize =>
			@cvs.width = @cvs.clientWidth
			@cvs.height = @cvs.clientHeight
			@redraw()
		@ctx = @cvs.getContext '2d'
		@img = $('#src')[0]
		
		@offX = 0
		@offY = 0
		if @img.width > @img.height and @img.width > @cvs.width
			@scale = @cvs.width / @img.width
		else if @img.height > @cvs.height
			@scale = @cvs.height / @img.height
		else
			@scale = 1
		@redraw()

		@dragging = false
		$(@cvs).mousedown (e) =>
			if newRegion == 0 and reshaping == 0
				@dragging = true
			@hasmoved = false
			@mousepos = [e.offsetX, e.offsetY]
		$(@cvs).mouseup =>
			@dragging = false
			clickpos = [@mousepos[0] / @scale + @offX, @mousepos[1] / @scale + @offY]
			if newRegion == 1
				newRegionPos = clickpos
				newRegion = 2
				$('#helper').text 'Select opposite corner of region'
			else if reshaping == 1
				newRegionPos = clickpos
				reshaping = 2
				$('#helper').text 'Select opposite corner of region'
			else if newRegion == 2
				[x, y] = newRegionPos
				[x2, y2] = clickpos
				if x > x2
					t = x2
					x2 = x
					x = t
				if y > y2
					t = y2
					y2 = y
					y = t
				regions.push [x, y, x2-x, y2-y, '', '']
				newRegion = 0
				$('#helper').text ''
				editRegion regions.length - 1
				@redraw()
				saveRegions()
				$('#de-text').focus()
			else if reshaping == 2
				[x, y] = newRegionPos
				[x2, y2] = clickpos
				if x > x2
					t = x2
					x2 = x
					x = t
				if y > y2
					t = y2
					y2 = y
					y = t
				regions[currentRegion][0] = x
				regions[currentRegion][1] = y
				regions[currentRegion][2] = x2-x
				regions[currentRegion][3] = y2-y
				reshaping = 0
				$('#helper').text ''
				@redraw()
				saveRegions()
			else if not @hasmoved
				for region, i in regions
					[x, y, w, h, detext, entext] = region
					if x <= clickpos[0] and x+w >= clickpos[0] and y <= clickpos[1] and y+h >= clickpos[1]
						if i != currentRegion
							editRegion i
							@redraw()
						break
		$(@cvs).mousemove (e) =>
			curpos = [e.offsetX / @scale + @offX, e.offsetY / @scale + @offY]
			if newRegion == 1 or reshaping == 1
				@redraw()
				@ctx.strokeStyle = 'green'
				@ctx.beginPath()
				@ctx.rect (curpos[0] - @offX) * @scale, (curpos[1] - @offY) * @scale, 20, 20
				@ctx.stroke()
				@ctx.closePath()
			else if newRegion == 2 or reshaping == 2
				@redraw()
				@ctx.strokeStyle = 'green'
				@ctx.beginPath()
				[x, y] = [(newRegionPos[0] - @offX) * @scale, (newRegionPos[1] - @offY) * @scale]
				@ctx.rect x, y, (curpos[0] - newRegionPos[0]) * @scale, (curpos[1] - newRegionPos[1]) * @scale
				@ctx.stroke()
				@ctx.closePath()
			else if @dragging
				cur = [e.offsetX, e.offsetY]
				delta = [cur[0] - @mousepos[0], cur[1] - @mousepos[1]]
				@offX -= delta[0] / @scale
				@offY -= delta[1] / @scale
				@redraw()
				@mousepos = cur
				@hasmoved = true
		$(@cvs).mousewheel (e) =>
			delt = Math.abs(e.deltaY) / e.deltaY * .01
			curpos = [e.offsetX / @scale + @offX, e.offsetY / @scale + @offY]
			@scale += delt
			rspos = [e.offsetX / @scale + @offX, e.offsetY / @scale + @offY]
			@offX -= rspos[0] - curpos[0]
			@offY -= rspos[1] - curpos[1]
			@redraw()
		$(@cvs).dblclick (e) =>
			newRegion = 2
			newRegionPos = [e.offsetX / @scale + @offX, e.offsetY / @scale + @offY]
			$('#helper').text 'Select opposite corner of region'

	redraw: ->
		@ctx.clearRect 0, 0, @cvs.width, @cvs.height
		@ctx.drawImage @img, -@offX * @scale, -@offY * @scale, @img.width * @scale, @img.height * @scale
		for region, i in regions
			[x, y, w, h, detext, entext] = region
			if i == currentRegion
				@ctx.lineWidth = 2
				@ctx.strokeStyle = 'red'
			else if detext[0] == '!' and detext[1] == '!'
				@ctx.lineWidth = 2
				@ctx.strokeStyle = 'purple'
			else
				@ctx.lineWidth = 1
				@ctx.strokeStyle = 'blue'
			
			[sx, sy, sw, sh] = [Math.round((x - @offX) * @scale), Math.round((y - @offY) * @scale), Math.round(w * @scale), Math.round(h * @scale)]

			if not showEnglish
				@ctx.beginPath()
				@ctx.rect sx, sy, sw, sh
				@ctx.stroke()
				@ctx.closePath()
			else
				data = @ctx.getImageData(sx, sy, 1, 1).data
				if data[3] == 0
					@ctx.fillStyle = @defaultfill
				else
					@defaultfill = @ctx.fillStyle = '#' + ('000000' + ((data[0] << 16) | (data[1] << 8) | data[2]).toString(16)).slice(-6)
				@ctx.beginPath()
				@ctx.rect sx, sy, sw, sh
				@ctx.fill()
				@ctx.closePath()

				@ctx.save()
				if sh > sw
					@ctx.translate sx, sy + sh
					@ctx.rotate -Math.PI / 2
					rotated = true
					t = sh
					sh = sw
					sw = t
					sx = sy = 0

				@ctx.fillStyle = 'black'
				@ctx.textBaseline = 'top'
				fh = sh
				while true
					@ctx.font = 'normal normal 300 ' + fh + 'px "Roboto Slab"'
					meas = @ctx.measureText entext
					if meas.width > sw and fh > 0
						fh -= .1
					else
						break
				@ctx.fillText entext, sx, sy

				@ctx.restore()

editRegion = (i) ->
	currentRegion = i
	[x, y, w, h, detext, entext] = regions[i]
	$('#de-text').val detext
	$('#en-text').val entext
	$('#edit').show()

saveRegions = ->
	$rpc.index.save $('#main').data('fn'), regions
	cvsh.redraw()

$(window).load ->
	cvsh = new CanvasHelper

	if $('#status').val() == 'Not Started'
		$('#status').val('In Progress')
		$('#save-status').click()

	$('#to-translate').click () ->
		translate $('#de-text').val()

	$('#save').click ->
		if currentRegion != -1
			regions[currentRegion][4] = $('#de-text').val()
			regions[currentRegion][5] = $('#en-text').val()
			saveRegions()
	$('#delete').click ->
		if confirm 'Are you ABSOLUTELY SURE you want to delete this region?'
			regions.splice currentRegion, 1
			currentRegion = -1
			cvsh.redraw()
			saveRegions()

	$('#new-region').click ->
		newRegion = 1
		$('#helper').text 'Select top-left point of region'
	$('#reshape').click ->
		reshaping = 1
		$('#helper').text 'Select top-left point of region'
	$('#toggle-labels').click ->
		showEnglish = not showEnglish
		cvsh.redraw()
	$('.quick-text').click (e) ->
		target = $(e.target)
		$('#en-text').val target.data('en')
		$('#de-text').val target.data('de')
		$('#save').click()
	$('#save-status').click ->
		$rpc.index.set_status $('#main').data('fn'), $('#status').val()

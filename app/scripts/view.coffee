
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
		@defaultfill = 'white'
		
		@offX = 0#@img.width / 2
		@offY = 0#@img.height / 2
		if @img.width > @img.height and @img.width > @cvs.width
			@scale = @cvs.width / @img.width
		else if @img.height > @cvs.height
			@scale = @cvs.height / @img.height
		@redraw()

		@dragging = false
		$(@cvs).mousedown (e) =>
			@dragging = true
			@mousepos = [e.offsetX, e.offsetY]
		$(@cvs).mouseup =>
			@dragging = false
		$(@cvs).mousemove (e) =>
			if @dragging
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

	redraw: ->
		@ctx.clearRect 0, 0, @cvs.width, @cvs.height
		@ctx.drawImage @img, -@offX * @scale, -@offY * @scale, @img.width * @scale, @img.height * @scale
		for region, i in regions
			@ctx.lineWidth = 1
			@ctx.strokeStyle = 'blue'
			[x, y, w, h, _, entext] = region
			[sx, sy, sw, sh] = [Math.round((x - @offX) * @scale), Math.round((y - @offY) * @scale), Math.round(w * @scale), Math.round(h * @scale)]

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
			fh = sh * .9
			while true
				@ctx.font = 'normal normal 300 ' + fh + 'px "Roboto Slab"'
				meas = @ctx.measureText entext
				if meas.width > sw and fh > 0
					fh -= .1
				else
					break
			@ctx.fillText entext, sx, sy

			@ctx.restore()

	save: ->
		@cvs.width = @img.width
		@cvs.height = @img.height
		[os, ox, oy] = [@scale, @offX, @offY]
		@scale = 1
		@offX = 0
		@offY = 0
		@redraw()
		url = @cvs.toDataURL()
		window.open url

$(window).load ->
	cvsh = new CanvasHelper

	$('#save').click ->
		cvsh.save()

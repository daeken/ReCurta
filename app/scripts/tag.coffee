window.toggle = (num) ->
	$('#select_' + num).prop 'checked', !($('#select_' + num).prop 'checked')

$(document).ready ->
	$('.save').click ->
		refs = []
		$('.part-select').each (i, el) ->
			el = $(el)
			if el.prop 'checked'
				refs.push el.data('num')
		$rpc.index.save_part_refs $('#img').data('fn'), refs

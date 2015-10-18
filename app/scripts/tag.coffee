window.toggle = (num) ->
	$('#select_' + num).prop 'checked', !($('#select_' + num).prop 'checked')

$(document).ready ->

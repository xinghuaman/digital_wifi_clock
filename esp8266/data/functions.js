function val(id){
 var v = document.getElementById(id).value;
 return v;
}

function send_request(submit,server)
{
	request = new XMLHttpRequest();
	request.open("GET", server, true);
	request.send();
	save_status(submit,request);
}

function save_status(submit,request)
{
	old_submit = submit.value;
	request.onreadystatechange = function() 
	{
		if (request.readyState != 4) return;
		submit.value = request.responseText;
		setTimeout(function()
		{
			submit.value=old_submit;
			submit_disabled(false);
		}, 	1000);
	}
	submit.value = 'Подождите...';
	submit_disabled(true);
}

function submit_disabled(request)
{
	var inputs = document.getElementsByTagName("input");
	for (var i = 0; i < inputs.length; i++) 
	{
		if (inputs[i].type === 'submit') 
		{
			inputs[i].disabled = request;
		}
	}
}

function toggle(target) 
{
	var curVal = document.getElementById(target).className;
	document.getElementById(target).className = (curVal === 'hidden') ? 'show' : 'hidden';
}
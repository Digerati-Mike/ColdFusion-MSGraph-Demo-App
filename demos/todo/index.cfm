<cfscript>

	// Determine login state
	isLoggedIn = structKeyExists(session, "LoggedIn") && !!session.LoggedIn && structKeyExists(session, "Tokens");

	// Initialize graph client when logged in
	if ( isLoggedIn ) {
		graphclient = new com.graphClient({
			"access_token" : session.Tokens.main.access_token
		});
	}

	// Simple JSON response helper
	function jsonResponse(data){
		// Output JSON and stop rendering rest of page
		cfheader(name="Content-Type", value="application/json; charset=utf-8");
		writeOutput(serializeJSON(data));
		abort;
	}

	// Only accept AJAX/action calls when logged in. Require LoggedIn and an action (from url or form) or any non-GET request.
	if ( isLoggedIn && ( structKeyExists(url, "action") || structKeyExists(form, "action") || CGI.REQUEST_METHOD != 'GET' ) ) {

		// Determine action from url (GET) or form (POST)
		if ( structKeyExists(url, "action") ) {
			action = url.action;
		} else if ( structKeyExists(form, "action") ) {
			action = form.action;
		} else {
			action = "";
		}

		try {
			switch (action) {
				case 'getLists':
					lists = graphclient.send('/me/todo/lists');
					jsonResponse({"success" :true, "data":lists});
					break;

				case 'getTasks':
					// listId may be sent via querystring (url) or POST body (form)
					listId = structKeyExists(url, 'listId') ? url.listId : ( structKeyExists(form, 'listId') ? form.listId : '' );
					tasks = graphclient.send('/me/todo/lists/' & listId & '/tasks?$orderby=createdDateTime desc');
					jsonResponse({"success" :true, "data":tasks});
					break;

				case 'createList':
					payload = { displayName = form.displayName };
					resp = graphclient.send('/me/todo/lists', { method = 'POST', body = serializeJSON( payload ) });
					jsonResponse({"success" :true, "data":resp});
					break;

				case 'updateList':
					listId = form.listId;
					payload = { displayName = form.displayName };
					resp = graphclient.send('/me/todo/lists/' & listId, { method = 'PATCH', body = serializeJSON( payload ) });
					jsonResponse({"success" :true, "data":resp});
					break;

				case 'deleteList':
					listId = form.listId;
					resp = graphclient.send('/me/todo/lists/' & listId, { method = 'DELETE'});
					jsonResponse({"success" :true});
					break;

				case 'createTask':
					listId = form.listId;
					payload = { title = form.title };
				
					resp = graphclient.send('/me/todo/lists/' & listId & '/tasks', { method = 'POST', body = serializeJSON( payload ) });
					jsonResponse({"success" :true, "data":resp, "payload" : payload});
					break;

				case 'updateTask':
					listId = form.listId;
					taskId = form.taskId;
					payload = {};
					if ( structKeyExists(form,'title') ) payload.title = form.title;
					if ( structKeyExists(form,'body') ) payload.body = { content = form.body, contentType = 'text' };
					if ( structKeyExists(form,'status') ) payload.status = form.status; // not always used
					resp = graphclient.send('/me/todo/lists/' & listId & '/tasks/' & taskId, { method = 'PATCH', body = serializeJSON( payload ) });
					jsonResponse({"success" :true, "data":resp});
					break;

				case 'deleteTask':
					listId = form.listId;
					taskId = form.taskId;
					resp = graphclient.send('/me/todo/lists/' & listId & '/tasks/' & taskId, { method = 'DELETE'});
					jsonResponse({"success" :true});
					break;

				case 'toggleComplete':
					listId = form.listId;
					taskId = form.taskId;
					complete = form.complete == 'true' || form.complete == 1 || form.complete == true;
					if ( complete ) {
						resp = graphclient.send('/me/todo/lists/' & listId & '/tasks/' & taskId & '/complete', { method = 'POST'});
					} else {
						resp = graphclient.send('/me/todo/lists/' & listId & '/tasks/' & taskId & '/undoComplete', { method = 'POST'});
					}
					jsonResponse({"success" :true});
					break;

				default:
					jsonResponse({"success" :false, message:'Unknown action.'});
			}
		} catch(any e) {
			// Try to return Graph error information if available
			err = { success = false, message = e };
			if ( structKeyExists(e, 'detail') ) err.detail = e.detail;
			jsonResponse(err);
		}
	}

</cfscript>


<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Vault Token - Summit Demo</title>
    <!-- Bootstrap 5 CSS -->
	<link href="/assets/bootstrap.min.css" rel="stylesheet" >
	<!-- Font Awesome 6 -->
	<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/all.min.css" rel="stylesheet"/>
	<style>
		body { background: #f8f9fa; }
		.sidebar { min-height: calc(100vh - 56px); }
		.list-item { cursor: pointer; }
		.task-complete { text-decoration: line-through; opacity: 0.6; }
	</style>
    <script src="/assets/jquery.min.js"></script>
</head>
<body>
    <nav class="navbar navbar-expand-lg bg-dark navbar-dark">
		<div class="container">
			<a class="navbar-brand" href="/">
				<i class="fa-solid fa-mountain-sun me-2"></i>
				CFSummit Demo - To Do
			</a>
		
			<form method="post" class="d-inline">
				<button name="logout" value="1" class="btn btn-sm btn-outline-light">Logout</button>
			</form>
		</div>
	</nav>


	<main class="container py-4">
		<div class="row">
			<div class="col-md-4">
				<div class="card sidebar">
					<div class="card-header d-flex justify-content-between align-items-center">
						<strong>Lists</strong>
						<div>
							<button id="btnAddList" class="btn btn-sm btn-primary">New List</button>
						</div>
					</div>
					<div class="list-group list-group-flush" id="listsContainer">
						<!-- Lists loaded here -->
					</div>
				</div>
			</div>
			<div class="col-md-8">
				<div class="card">
					<div class="card-header d-flex justify-content-between align-items-center">
						<strong id="currentListName">Select a list</strong>
						<div>
							<button id="btnAddTask" class="btn btn-sm btn-success" disabled>New Task</button>
						</div>
					</div>
					<div class="card-body">
						<ul class="list-group" id="tasksContainer">
							<!-- Tasks loaded here -->
						</ul>
					</div>
				</div>
			</div>
		</div>
	</main>

	<!-- Modals -->
	<div class="modal fade" id="modalList" tabindex="-1">
		<div class="modal-dialog">
			<div class="modal-content">
				<form id="formList">
					<div class="modal-header">
						<h5 class="modal-title">List</h5>
						<button type="button" class="btn-close" data-bs-dismiss="modal"></button>
					</div>
					<div class="modal-body">
						<input type="hidden" name="listId" />
						<div class="mb-3">
							<label class="form-label">Name</label>
							<input class="form-control" name="displayName" required />
						</div>
					</div>
					<div class="modal-footer">
						<button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
						<button type="submit" class="btn btn-primary">Save</button>
					</div>
				</form>
			</div>
		</div>
	</div>

	<div class="modal fade" id="modalTask" tabindex="-1">
		<div class="modal-dialog">
			<div class="modal-content">
				<form id="formTask">
					<div class="modal-header">
						<h5 class="modal-title">Task</h5>
						<button type="button" class="btn-close" data-bs-dismiss="modal"></button>
					</div>
					<div class="modal-body">
						<input type="hidden" name="listId" />
						<input type="hidden" name="taskId" />
						<div class="mb-3">
							<label class="form-label">Title</label>
							<input class="form-control" name="title" required />
						</div>
						<div class="mb-3">
							<label class="form-label">Notes</label>
							<textarea class="form-control" name="body"></textarea>
						</div>
					</div>
					<div class="modal-footer">
						<button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
						<button type="submit" class="btn btn-primary">Save Task</button>
					</div>
				</form>
			</div>
		</div>
	</div>

	<!-- Bootstrap 5 JS Bundle -->
	<script src="/assets/bootstrap.bundle.min.js" ></script>

	<script>
	$(function(){
		let currentListId = null;

		function api(action, data, method){
			method = method || (data? 'POST' : 'GET');
			return $.ajax({
				url: '/demos/todo/index.cfm',
				"data": Object.assign({ action: action }, data || {}),
				type: method
			});
		}

		function loadLists(){
			api('getLists').done(function(resp){
				if(!resp.success) return alert('Error loading lists');
				$('#listsContainer').empty();
				let lists = resp.data.value || resp.data; // handle different shapes
                console.log(lists)
				lists.forEach(function(l){
					let item = $('<a class="list-group-item list-group-item-action d-flex justify-content-between align-items-center list-item"></a>')
						.text(l.displayName)
						.data('list', l)
						.click(function(){
							$('.list-group .active').removeClass('active');
							$(this).addClass('active');
							selectList(l);
						});
					let actions = $('<div></div>');
					actions.append('<button class="btn btn-sm btn-light me-1 btn-edit-list" title="Edit"><i class="fa fa-pen"></i></button>');
					actions.append('<button class="btn btn-sm btn-danger btn-delete-list" title="Delete"><i class="fa fa-trash"></i></button>');
					item.append(actions);
					$('#listsContainer').append(item);
				});
			}).fail(function(){ alert('Failed to load lists'); });
		}

		function selectList(list){
			currentListId = list.id;
			$('#currentListName').text(list.displayName);
			$('#btnAddTask').prop('disabled', false).data('listId', list.id);
			loadTasks(list.id);
		}
        function loadTasks(listId){
            api('getTasks', { listId: listId }, 'GET').done(function(resp){
                if(!resp.success) return alert('Error loading tasks');
                $('#tasksContainer').empty();
                let tasks = resp.data.value || resp.data;
                if(!tasks || tasks.length === 0) {
                    $('#tasksContainer').append('<li class="list-group-item">No tasks</li>');
                    return;
                }
                tasks.forEach(function(t){
                    let li = $('<li class="list-group-item d-flex justify-content-between align-items-start"></li>');
                    let left = $('<div class="ms-2 me-auto"></div>');
                    let title = $('<div class="fw-bold task-title"></div>').text(t.title);
                    if(t.status && t.status.toLowerCase() === 'completed') title.addClass('task-complete');
                    left.append(title);
                    if(t.body && t.body.content) left.append($('<div class="small text-muted"></div>').text(t.body.content));
                    let btnGroup = $('<div></div>');
                    btnGroup.append('<button class="btn btn-sm btn-outline-success me-1 btn-toggle-complete">' + (t.status && t.status.toLowerCase()==='completed' ? '<i class="fa fa-undo"></i>' : '<i class="fa fa-check"></i>') + '</button>');
                    btnGroup.append('<button class="btn btn-sm btn-light me-1 btn-edit-task">Edit</button>');
                    btnGroup.append('<button class="btn btn-sm btn-danger btn-delete-task">Delete</button>');
                    li.append(left).append(btnGroup);
                    li.data('task', t).data('listId', listId);
                    $('#tasksContainer').append(li);
                });
            }).fail(function(){ alert('Failed to load tasks'); });
        }

		// Events
		$('#btnAddList').click(function(){
			$('#formList')[0].reset();
			$('#formList [name=listId]').val('');
			new bootstrap.Modal(document.getElementById('modalList')).show();
		});

		$('#listsContainer').on('click', '.btn-edit-list', function(e){
			e.stopPropagation();
			let l = $(this).closest('.list-item, a').data('list');
			$('#formList [name=listId]').val(l.id);
			$('#formList [name=displayName]').val(l.displayName);
			new bootstrap.Modal(document.getElementById('modalList')).show();
		});

		$('#listsContainer').on('click', '.btn-delete-list', function(e){
			e.stopPropagation();
			let l = $(this).closest('a').data('list');
			if(!confirm('Delete list "' + l.displayName + '"?')) return;
			api('deleteList', { listId: l.id }).done(function(){ loadLists(); $('#tasksContainer').empty(); $('#currentListName').text('Select a list'); $('#btnAddTask').prop('disabled', true); }).fail(function(){ alert('Delete failed'); });
		});

		$('#formList').submit(function(e){
			e.preventDefault();
			let data = $(this).serializeArray().reduce(function(m,v){ m[v.name]=v.value; return m; }, {});
			let action = data.listId ? 'updateList' : 'createList';
			$.post('/demos/todo/index.cfm', $.extend({ action: action }, data)).done(function(resp){
				if(!resp.success) return alert('Error saving list');
				loadLists();
				bootstrap.Modal.getInstance(document.getElementById('modalList')).hide();
			}).fail(function(){ alert('Save failed'); });
		});

		$('#btnAddTask').click(function(){
			$('#formTask')[0].reset();
			$('#formTask [name=listId]').val($(this).data('listId') || currentListId);
			$('#formTask [name=taskId]').val('');
			new bootstrap.Modal(document.getElementById('modalTask')).show();
		});

		$('#tasksContainer').on('click', '.btn-edit-task', function(){
			let t = $(this).closest('li').data('task');
			let listId = $(this).closest('li').data('listId');
			$('#formTask [name=listId]').val(listId);
			$('#formTask [name=taskId]').val(t.id);
			$('#formTask [name=title]').val(t.title);
			$('#formTask [name=body]').val(t.body && t.body.content ? t.body.content : '');
			new bootstrap.Modal(document.getElementById('modalTask')).show();
		});

		$('#tasksContainer').on('click', '.btn-delete-task', function(){
			let t = $(this).closest('li').data('task');
			let listId = $(this).closest('li').data('listId');
			if(!confirm('Delete task "' + t.title + '"?')) return;
			api('deleteTask', { listId: listId, taskId: t.id }).done(function(){ loadTasks(listId); }).fail(function(){ alert('Delete failed'); });
		});

		$('#tasksContainer').on('click', '.btn-toggle-complete', function(){
			let li = $(this).closest('li');
			let t = li.data('task');
			let listId = li.data('listId');
			let complete = !(t.status && t.status.toLowerCase()==='completed');
			api('toggleComplete', { listId: listId, taskId: t.id, complete: complete }).done(function(){ loadTasks(listId); }).fail(function(){ alert('Operation failed'); });
		});

		$('#formTask').submit(function(e){
			e.preventDefault();
			let data = $(this).serializeArray().reduce(function(m,v){ m[v.name]=v.value; return m; }, {});
			let action = data.taskId ? 'updateTask' : 'createTask';
			$.post('/demos/todo/index.cfm', $.extend({ action: action }, data)).done(function(resp){
				if(!resp.success) return alert('Error saving task');
				loadTasks(data.listId);
				bootstrap.Modal.getInstance(document.getElementById('modalTask')).hide();
			}).fail(function(){ alert('Save failed'); });
		});

		// Initial load
		loadLists();
	});
	</script>
</body>
</html>
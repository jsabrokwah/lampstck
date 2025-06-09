document.addEventListener('DOMContentLoaded', function() {
    // DOM elements
    const newTodoInput = document.getElementById('new-todo');
    const addBtn = document.getElementById('add-btn');
    const todoList = document.getElementById('todos');
    
    // Load todos on page load
    loadTodos();
    
    // Add event listener for adding new todos
    addBtn.addEventListener('click', addTodo);
    newTodoInput.addEventListener('keypress', function(e) {
        if (e.key === 'Enter') {
            addTodo();
        }
    });
    
    // Function to load todos from API
    function loadTodos() {
        fetch('api/get_todos.php')
            .then(response => response.json())
            .then(data => {
                todoList.innerHTML = '';
                data.forEach(todo => {
                    addTodoToDOM(todo);
                });
            })
            .catch(error => console.error('Error loading todos:', error));
    }
    
    // Function to add a new todo
    function addTodo() {
        const todoText = newTodoInput.value.trim();
        if (todoText === '') return;
        
        fetch('api/add_todo.php', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: `task=${encodeURIComponent(todoText)}`
        })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                addTodoToDOM(data.todo);
                newTodoInput.value = '';
            }
        })
        .catch(error => console.error('Error adding todo:', error));
    }
    
    // Function to mark a todo as complete
    function completeTodo(id) {
        fetch('api/complete_todo.php', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: `id=${id}`
        })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                loadTodos(); // Reload todos to reflect changes
            }
        })
        .catch(error => console.error('Error completing todo:', error));
    }
    
    // Function to delete a todo
    function deleteTodo(id) {
        fetch('api/delete_todo.php', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: `id=${id}`
        })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                document.getElementById(`todo-${id}`).remove();
            }
        })
        .catch(error => console.error('Error deleting todo:', error));
    }
    
    // Function to add a todo to the DOM
    function addTodoToDOM(todo) {
        const li = document.createElement('li');
        li.id = `todo-${todo.id}`;
        li.className = `todo-item ${todo.completed ? 'completed' : ''}`;
        
        const span = document.createElement('span');
        span.textContent = todo.task;
        li.appendChild(span);
        
        const completeBtn = document.createElement('button');
        completeBtn.className = 'complete-btn';
        completeBtn.textContent = todo.completed ? 'Undo' : 'Complete';
        completeBtn.addEventListener('click', () => completeTodo(todo.id));
        li.appendChild(completeBtn);
        
        const deleteBtn = document.createElement('button');
        deleteBtn.className = 'delete-btn';
        deleteBtn.textContent = 'Delete';
        deleteBtn.addEventListener('click', () => deleteTodo(todo.id));
        li.appendChild(deleteBtn);
        
        todoList.appendChild(li);
    }
});
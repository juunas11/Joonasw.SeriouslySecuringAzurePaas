(function () {
    function completeTodo(id) {
        document.getElementById("completeId").value = id;
        document.getElementById("completeForm").submit();
    }

    function deleteTodo(id) {
        document.getElementById("deleteId").value = id;
        document.getElementById("deleteForm").submit();
    }

    const completeButtons = document.getElementsByClassName("btn-complete-todo");
    for (let i = 0; i < completeButtons.length; i++) {
        completeButtons[i].addEventListener("click", function () {
            completeTodo(this.getAttribute("data-id"));
        });
    }

    const deleteButtons = document.getElementsByClassName("btn-delete-todo");
    for (let i = 0; i < deleteButtons.length; i++) {
        deleteButtons[i].addEventListener("click", function () {
            deleteTodo(this.getAttribute("data-id"));
        });
    }
}());
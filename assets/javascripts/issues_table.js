$(document).ready(function() {
    const projectSelect = $('#project-select');
    const issuesTableContainer = $('#issues-table-container');
    const toggleTableBtn = $('#toggle-issues-table');
    const newIssueBtn = $('#new-issue-btn');
    const newIssueModal = $('#new-issue-modal');
    const issuesTableBody = $('#issues-table-body');

    let currentSort = { column: 'id', direction: 'asc' };

    // Показ/скрытие таблицы
    toggleTableBtn.on('click', function() {
        if (issuesTableContainer.is(':hidden')) {
            loadIssuesTable();
        }
        issuesTableContainer.toggle();
    });

    // Загрузка данных таблицы
    function loadIssuesTable() {
        const projectId = projectSelect.val();
        if (!projectId) return;

        $.ajax({
            url: `/projects/${projectId}/issues_table`,
            data: { sort: currentSort.column, direction: currentSort.direction },
            success: function(data) {
                renderIssuesTable(data);
            }
        });
    }

    // Отрисовка таблицы
    function renderIssuesTable(issues) {
        issuesTableBody.empty();

        issues.forEach(issue => {
            const row = $('<tr>').append(
                $('<td>').text(issue.id),
                $('<td>').text(issue.subject),
                $('<td>').text(issue.status),
                $('<td>').text(issue.version),
                $('<td>').text(issue.start_date),
                $('<td>').text(issue.due_date),
                $('<td>').text(issue.parent_issue),
                $('<td>').text(issue.subtask)
            );
            issuesTableBody.append(row);
        });
    }

    // Обработка сортировки
    $('.sortable').on('click', function() {
        const column = $(this).data('sort');
        if (currentSort.column === column) {
            currentSort.direction = currentSort.direction === 'asc' ? 'desc' : 'asc';
        } else {
            currentSort.column = column;
            currentSort.direction = 'asc';
        }
        loadIssuesTable();
    });

    // Управление модальным окном
    newIssueBtn.on('click', function() {
        newIssueModal.show();
    });

    $('#cancel-issue-btn').on('click', function() {
        newIssueModal.hide();
    });

    // Создание новой задачи
    $('#new-issue-form').on('submit', function(e) {
        e.preventDefault();
        const formData = $(this).serialize();

        $.ajax({
            url: '/reports/create_issue',
            method: 'POST',
            data: formData,
            success: function(response) {
                newIssueModal.hide();
                loadIssuesTable();
            }
        });
    });

    // Обновление таблицы при изменении проекта
    projectSelect.on('change', function() {
        if (issuesTableContainer.is(':visible')) {
            loadIssuesTable();
        }
    });
});
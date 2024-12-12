$(document).ready(function() {
    // DOM элементы
    const projectSelect = $('#project-select');
    const versionSelect = $('#version-select'); // Добавлен элемент версии
    const issuesTableContainer = $('#issues-table-container');
    const toggleTableBtn = $('#toggle-issues-table');
    const newIssueBtn = $('#new-issue-btn');
    const newIssueModal = $('#new-issue-modal');
    const issuesTableBody = $('#issues-table-body');
    const modalVersionSelect = $('#issue_fixed_version_id');
    const modalAssigneeSelect = $('#issue_assigned_to_id');
    const newIssueForm = $('#new-issue-form');

    // Состояние сортировки
    let currentSort = { column: 'id', direction: 'asc' };

    // Функция проверки проекта и управления кнопкой создания задачи
    function updateNewIssueButton() {
        // Если у нас скрытое поле project_id, значит мы в контексте проекта
        const hiddenProjectField = $('input[name="report[project_id]"][type="hidden"]');
        const projectId = hiddenProjectField.length > 0 ? hiddenProjectField.val() : projectSelect.val();

        if (projectId) {
            newIssueBtn.prop('disabled', false);
            newIssueBtn.attr('title', '');
        } else {
            newIssueBtn.prop('disabled', true);
            newIssueBtn.attr('title', 'Выберите проект для создания задачи');
        }
    }

    // Загрузка исполнителей для проекта
    function loadProjectAssignees() {
        const projectId = projectSelect.val();
        modalAssigneeSelect.empty();
        modalAssigneeSelect.append($('<option>', {
            value: '',
            text: '--- Выберите исполнителя ---'
        }));

        if (!projectId) {
            modalAssigneeSelect.prop('disabled', true);
            return;
        }

        modalAssigneeSelect.prop('disabled', false);

        $.ajax({
            url: `/projects/${projectId}/available_assignees`,
            method: 'GET',
            success: function(users) {
                users.forEach(user => {
                    modalAssigneeSelect.append($('<option>', {
                        value: user.id,
                        text: user.name
                    }));
                });
            }
        });
    }

    // Загрузка версий проекта
    function loadProjectVersions() {
        const projectId = projectSelect.val();
        modalVersionSelect.empty();
        modalVersionSelect.append($('<option>', {
            value: '',
            text: '--- Выберите версию ---'
        }));

        if (!projectId) {
            modalVersionSelect.prop('disabled', true);
            $('.version-notice').remove();
            modalVersionSelect.parent().append(
                '<p class="version-notice">Выберите проект для отображения доступных версий</p>'
            );
            return;
        }

        modalVersionSelect.prop('disabled', false);
        $('.version-notice').remove();

        $.ajax({
            url: '/reports/load_project_versions',
            data: { project_id: projectId },
            success: function(versions) {
                versions.forEach(version => {
                    modalVersionSelect.append($('<option>', {
                        value: version.id,
                        text: version.name
                    }));
                });
            }
        });
    }

    // Загрузка данных таблицы
    function loadIssuesTable() {
        // Если у нас скрытое поле project_id, значит мы в контексте проекта
        const hiddenProjectField = $('input[name="report[project_id]"][type="hidden"]');
        const projectId = hiddenProjectField.length > 0 ? hiddenProjectField.val() : projectSelect.val();
        const versionId = versionSelect.val();

        if (!projectId) {
            issuesTableBody.empty();
            return;
        }

        $.ajax({
            url: `/projects/${projectId}/issues/table_data`,
            method: 'GET',
            data: {
                sort: currentSort.column,
                direction: currentSort.direction,
                version_id: versionId
            },
            success: function(data) {
                renderIssuesTable(data);
            },
            error: function(xhr, status, error) {
                console.error('Ошибка загрузки данных:', error);
                issuesTableBody.empty();
                issuesTableBody.append(
                    '<tr><td colspan="8" class="text-center">Ошибка при загрузке данных</td></tr>'
                );
            }
        });
    }

    // Отрисовка таблицы
    function renderIssuesTable(issues) {
        issuesTableBody.empty();
        if (!issues.length) {
            issuesTableBody.append(
                '<tr><td colspan="8" class="text-center">Нет доступных задач</td></tr>'
            );
            return;
        }

        issues.forEach(issue => {
            const row = $('<tr>').append(
                $('<td>').text(issue.id),
                $('<td>').text(issue.subject),
                $('<td>').text(issue.status),
                $('<td>').text(issue.version || '-'),
                $('<td>').text(issue.start_date || '-'),
                $('<td>').text(issue.due_date || '-'),
                $('<td>').text(issue.parent_issue || '-'),
                $('<td>').text(issue.subtask || '-')
            );
            issuesTableBody.append(row);
        });
    }

    // Очистка модальной формы
    function resetModalForm() {
        newIssueForm[0].reset();
        $('.version-notice').remove();
        modalVersionSelect.prop('disabled', false);
        modalAssigneeSelect.prop('disabled', false);
    }

    // Обработчики событий

    // Показ/скрытие таблицы
    toggleTableBtn.on('click', function() {
        if (issuesTableContainer.is(':hidden')) {
            loadIssuesTable();
        }
        issuesTableContainer.toggle();
    });

    // Сортировка по колонкам
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

    // Открытие модального окна
    newIssueBtn.on('click', function() {
        const hiddenProjectField = $('input[name="report[project_id]"][type="hidden"]');
        const projectId = hiddenProjectField.length > 0 ? hiddenProjectField.val() : projectSelect.val();

        if (!projectId) return;
        resetModalForm();
        loadProjectVersions();
        loadProjectAssignees();
        newIssueModal.show();
    });

    // Закрытие модального окна
    $('#cancel-issue-btn').on('click', function() {
        newIssueModal.hide();
        resetModalForm();
    });

    // Отправка формы создания задачи
    newIssueForm.on('submit', function(e) {
        e.preventDefault();
        const hiddenProjectField = $('input[name="report[project_id]"][type="hidden"]');
        const projectId = hiddenProjectField.length > 0 ? hiddenProjectField.val() : projectSelect.val();

        if (!projectId) return;

        const formData = $(this).serialize() + `&project_id=${projectId}`;

        $.ajax({
            url: `/projects/${projectId}/issues`,
            method: 'POST',
            data: formData,
            success: function(response) {
                if (response.success) {
                    newIssueModal.hide();
                    resetModalForm();
                    loadIssuesTable();
                } else {
                    alert(response.errors.join('\n'));
                }
            },
            error: function(xhr) {
                alert('Ошибка при создании задачи. Попробуйте позже.');
            }
        });
    });

    // Обработка изменения проекта
    projectSelect.on('change', function() {
        updateNewIssueButton();
        if (issuesTableContainer.is(':visible')) {
            loadIssuesTable();
        }
    });

    versionSelect.on('change', function() {
        if (issuesTableContainer.is(':visible')) {
            loadIssuesTable();
        }
    });

    // Инициализация при загрузке страницы
    updateNewIssueButton();
});
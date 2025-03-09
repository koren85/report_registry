// plugins/report_registry/assets/javascripts/issues_table.js
function initializeReportIssues() {
    const selectAllCheckbox = document.getElementById('select-all-issues');
    const deleteButton = document.getElementById('delete-selected-issues');

    function initializeCheckboxes() {
        // Получаем актуальный список чекбоксов
        const issueCheckboxes = document.querySelectorAll('.issue-checkbox');

        // Отключаем существующие обработчики
        $(document).off('change', '.issue-checkbox');
        $(selectAllCheckbox).off('change');

        // Добавляем обработчик на "выбрать все"
        $(selectAllCheckbox).on('change', function() {
            const isChecked = this.checked;
            issueCheckboxes.forEach(checkbox => {
                checkbox.checked = isChecked;
            });
            toggleDeleteButton();
        });

        // Добавляем обработчики на отдельные чекбоксы через делегирование
        $(document).on('change', '.issue-checkbox', function() {
            toggleDeleteButton();

            // Проверяем, нужно ли снять "выбрать все"
            if (!this.checked && selectAllCheckbox.checked) {
                selectAllCheckbox.checked = false;
            }
        });

        // Сброс начального состояния
        if (selectAllCheckbox) {
            selectAllCheckbox.checked = false;
        }
        toggleDeleteButton();
    }

    function toggleDeleteButton() {
        const hasChecked = $('.issue-checkbox:checked').length > 0;
        if (deleteButton) {
            deleteButton.style.display = hasChecked ? 'inline-block' : 'none';
        }
    }

    function updateSelect2Options(removedIds) {
        const $issuesSelect = $('#issues-select');
        if ($issuesSelect.length) {
            removedIds.forEach(id => {
                $issuesSelect.find(`option[value="${id}"]`).remove();
            });
            $issuesSelect.trigger('change');
        }
    }

    function checkTableEmpty() {
        const tbody = $('#report-issues-body');
        if (tbody.length && tbody.children().length === 0) {
            tbody.html('<tr><td colspan="10" class="text-center">Нет задач</td></tr>');
            if (deleteButton) deleteButton.style.display = 'none';
            if (selectAllCheckbox) selectAllCheckbox.checked = false;
        }
    }

    // Обработчик массового удаления
    $(deleteButton).off('click').on('click', function(e) {
        e.preventDefault();
        e.stopPropagation();

        const selectedIds = $('.issue-checkbox:checked').map(function() {
            return this.value;
        }).get();

        if (selectedIds.length === 0) {
            alert('Выберите хотя бы одну задачу.');
            return false;
        }

        if (!confirm('Вы уверены, что хотите удалить выбранные задачи?')) {
            return false;
        }

        const reportId = this.dataset.reportId;
        const projectIdentifier = this.dataset.projectIdentifier;
        const token = document.querySelector('meta[name="csrf-token"]').content;

        const url = projectIdentifier ?
            `/projects/${projectIdentifier}/registry_reports/${reportId}/report_issues/remove_issues` :
            `/registry_reports/${reportId}/report_issues/remove_issues`;

        $.ajax({
            url: url,
            type: 'DELETE',
            data: { issue_ids: selectedIds },
            headers: {
                'X-CSRF-Token': token
            },
            success: function(response) {
                selectedIds.forEach(id => {
                    $(`#issue-row-${id}`).fadeOut('fast', function() {
                        $(this).remove();
                        checkTableEmpty();
                    });
                });

                updateSelect2Options(selectedIds);

                if (selectAllCheckbox) {
                    selectAllCheckbox.checked = false;
                }
                toggleDeleteButton();

                const notice = $('<div class="flash notice">')
                    .text('Успешно удалено')
                    .hide()
                    .prependTo('#content')
                    .fadeIn();

                setTimeout(() => notice.fadeOut(() => notice.remove()), 3000);
            },
            error: function(xhr, status, error) {
                console.error('Error:', error);
                alert('Произошла ошибка при удалении задач');
            }
        });

        return false;
    });

    // Инициализация при загрузке
    initializeCheckboxes();
    checkTableEmpty();
}

// Инициализация при загрузке страницы
$(document).ready(function() {
    initializeReportIssues();


        // Функция для автоматической подстройки высоты
        function autoResizeTextarea(textarea) {
            textarea.style.height = 'auto';
            textarea.style.height = (textarea.scrollHeight) + 'px';
        }

        // Применяем авторазмер ко всем полям при загрузке
        $('.report-title-field').each(function() {
            autoResizeTextarea(this);
        });

        // Обновляем размер при вводе текста
        $(document).on('input', '.report-title-field', function() {
            autoResizeTextarea(this);
        });
        // Обработчик изменения названия задачи
        $(document).on('change', '.report-title-field', function() {
            var $field = $(this);
            var url = $field.data('url');
            var originalValue = $field.data('original-value');

            $.ajax({
                url: url,
                type: 'PATCH',
                data: {
                    report_title: $field.val()
                },
                headers: {
                    'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
                },
                dataType: 'json',
                success: function(response) {
                    // Обновляем original-value в случае успеха
                    $field.data('original-value', $field.val());
                    // Добавляем эффект подсветки для индикации успешного сохранения
                    $field.closest('td').effect('highlight', {}, 1000);
                },
                error: function(xhr) {
                    // Возвращаем предыдущее значение в случае ошибки
                    alert(xhr.responseJSON?.error || 'Error updating title');
                    $field.val(originalValue);
                }
            });
        });
});

// Реинициализация после AJAX запросов
$(document).ajaxComplete(function(event, xhr, settings) {
    // Проверяем URL запроса
    if (settings.url.includes('add_issues') ||
        settings.url.includes('modal_issues') ||
        settings.url.includes('remove_issue')) {
        // Даем небольшую задержку, чтобы DOM успел обновиться
        setTimeout(initializeReportIssues, 100);
    }
});

// Делаем функцию доступной глобально
window.initializeReportIssues = initializeReportIssues;
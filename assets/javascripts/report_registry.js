// plugins/report_registry/assets/javascripts/report_registry.js
$(document).ready(function() {
    // Инициализация Select2
    $('.select2').select2();

    // Обработчик одиночного удаления задачи
    $(document).on('click', '.icon-del', function(e) {
        e.preventDefault();
        const $link = $(this);
        const $row = $link.closest('tr');
        const issueId = $row.data('issue-id');

        if (!confirm('Вы уверены?')) {
            return;
        }

        $.ajax({
            url: $link.attr('href'),
            type: 'DELETE',
            dataType: 'script',
            headers: {
                'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
            },
            success: function() {
                // Удаляем строку из таблицы
                $row.fadeOut('fast', function() {
                    $(this).remove();
                });

                // Обновляем select2
                const $issuesSelect = $('#issues-select');
                if ($issuesSelect.length) {
                    $issuesSelect.find(`option[value="${issueId}"]`).remove();
                    $issuesSelect.trigger('change');
                }

                // Показываем уведомление
                const notice = $('<div class="flash notice">')
                    .text('Успешно удалено')
                    .hide()
                    .prependTo('#content')
                    .fadeIn();

                setTimeout(() => notice.fadeOut(() => notice.remove()), 3000);
            },
            error: function() {
                alert('Произошла ошибка при удалении');
            }
        });
    });

    // Обработчик выбора проекта
    const $projectSelect = $('#project-select');
    const $versionSelect = $('#version-select');
    const $issuesSelect = $('#issues-select');

    if ($projectSelect.length) {
        $projectSelect.on('change', function() {
            const projectId = $(this).val();

            if (projectId) {
                // Загрузка версий
                $.ajax({
                    url: `/projects/${projectId}/reports/load_project_versions`,
                    type: 'GET',
                    dataType: 'json',
                    success: function(versions) {
                        $versionSelect.empty().append('<option value=""></option>');
                        versions.forEach(version => {
                            $versionSelect.append(
                                $('<option>', {
                                    value: version.id,
                                    text: version.name
                                })
                            );
                        });
                        $versionSelect.trigger('change');
                    }
                });
            } else {
                $versionSelect.empty().append('<option value=""></option>').trigger('change');
                $issuesSelect.empty().trigger('change');
            }
        });
    }
});
$(document).ready(function() {
    var projectSelect = $('#project-select');
    var versionSelect = $('#version-select');

    function initializeSelect2() {
        if ($.fn.select2) {
            versionSelect.select2({
                allowClear: true,
                placeholder: ''
            });
        }
    }

    function updateVersions(projectId) {
        if (projectId) {
            $.ajax({
                url: '/reports/load_project_versions',
                data: { project_id: projectId },
                method: 'GET',
                dataType: 'json'
            }).done(function(versions) {
                // Сохраняем текущее значение
                var currentValue = versionSelect.val();

                // Очищаем select
                versionSelect.empty();

                // Добавляем пустую опцию
                versionSelect.append($('<option>', {
                    value: '',
                    text: ''
                }));

                // Добавляем версии
                versions.forEach(function(version) {
                    versionSelect.append($('<option>', {
                        value: version.id,
                        text: version.name
                    }));
                });

                // Восстанавливаем значение если оно есть в новом списке
                if (currentValue && versions.some(v => v.id.toString() === currentValue.toString())) {
                    versionSelect.val(currentValue);
                }

                // Включаем select
                versionSelect.prop('disabled', false);

                // Обновляем select2 если он используется
                if ($.fn.select2) {
                    versionSelect.trigger('change.select2');
                }
            }).fail(function() {
                console.error('Failed to load versions');
                versionSelect.empty().prop('disabled', true);
            });
        } else {
            versionSelect.empty().prop('disabled', true);
            if ($.fn.select2) {
                versionSelect.trigger('change.select2');
            }
        }
    }

    // Инициализируем select2
    initializeSelect2();

    // Привязываем обработчик изменения проекта
    projectSelect.on('change', function() {
        updateVersions($(this).val());
    });

    // Если проект уже выбран при загрузке страницы, загружаем его версии
    var initialProjectId = projectSelect.val();
    if (initialProjectId) {
        updateVersions(initialProjectId);
    }
});
$(document).ready(function() {
    var projectSelect = $('#project-select');
    var versionSelect = $('#version-select');
    var periodSelect = $('#report_period');
    var contractInput = $('#report_contract_number');
    var nameInput = $('#report_name');
    var userEditedName = false;

    // Отслеживаем ручное редактирование названия
    nameInput.on('input', function() {
        userEditedName = true;
    });

    function updateReportName() {
        // Если пользователь уже редактировал название, не обновляем его
        if (userEditedName) return;

        var projectName = projectSelect.find('option:selected').text() || '';
        var versionName = versionSelect.find('option:selected').text() || '';
        var period = periodSelect.val() || '';
        var contract = contractInput.val() || '';

        // Формируем название только если есть хотя бы один компонент
        if (projectName || versionName || period || contract) {
            var components = [projectName, versionName, period, contract].filter(Boolean);
            var newName = components.join(' - ');
            nameInput.val(newName);
        }
    }

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
                var currentValue = versionSelect.val();
                versionSelect.empty();
                versionSelect.append($('<option>', {
                    value: '',
                    text: ''
                }));

                versions.forEach(function(version) {
                    versionSelect.append($('<option>', {
                        value: version.id,
                        text: version.name
                    }));
                });

                if (currentValue && versions.some(v => v.id.toString() === currentValue.toString())) {
                    versionSelect.val(currentValue);
                }

                versionSelect.prop('disabled', false);

                if ($.fn.select2) {
                    versionSelect.trigger('change.select2');
                }

                // Обновляем название после загрузки версий
                updateReportName();
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

    // Инициализация
    initializeSelect2();

    // Привязываем обработчики изменений
    projectSelect.on('change', function() {
        updateVersions($(this).val());
        updateReportName();
    });

    versionSelect.on('change', function() {
        updateReportName();
    });

    periodSelect.on('change', function() {
        updateReportName();
    });

    contractInput.on('input', function() {
        updateReportName();
    });

    // Если есть начальные значения
    var initialProjectId = projectSelect.val();
    if (initialProjectId) {
        updateVersions(initialProjectId);
    }

    // Если название уже заполнено при загрузке страницы, считаем что оно отредактировано пользователем
    if (nameInput.val()) {
        userEditedName = true;
    }
});
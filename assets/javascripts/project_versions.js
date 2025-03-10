$(document).ready(function() {
    var projectSelect = $('#project-select');
    var versionSelect = $('#version-select');

    function updateVersions(projectId) {
        if (projectId) {
            $.ajax({
                url: '/registry_reports/load_project_versions',
                data: { project_id: projectId },
                method: 'GET',
                dataType: 'json'
            }).done(function(versions) {
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

                versionSelect.prop('disabled', false);

                if ($.fn.select2) {
                    versionSelect.trigger('change.select2');
                }

                updateReportName();
            }).fail(function() {
                versionSelect.empty().prop('disabled', true);
            });
        } else {
            versionSelect.empty().prop('disabled', true);
            if ($.fn.select2) {
                versionSelect.trigger('change.select2');
            }
        }
    }

    projectSelect.on('change', function() {
        updateVersions($(this).val());
    });

    versionSelect.on('change', function() {
        updateReportName();
        // Сбрасываем select2 с задачами при изменении версии
        var $issuesSelect = $('#issues-select');
        if ($issuesSelect.length) {
            $issuesSelect.val(null).trigger('change');
        }
    });

    // Инициализация при загрузке
    var initialProjectId = projectSelect.val();
    if (initialProjectId) {
        updateVersions(initialProjectId);
    }
});
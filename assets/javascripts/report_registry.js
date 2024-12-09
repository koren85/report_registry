// plugins/report_registry/assets/javascripts/report_registry.js
$(document).ready(function() {
    $('.select2').select2();
});
// plugins/report_registry/assets/javascripts/report_registry.js
document.addEventListener('DOMContentLoaded', function () {
    const projectSelect = document.getElementById('project-select');
    const versionSelect = document.getElementById('version-select');
    const issuesSelect = document.getElementById('issues-select');

    if (projectSelect) {
        projectSelect.addEventListener('change', function () {
            const projectId = projectSelect.value;

            if (projectId) {
                // Загрузка версий
                fetch(`/projects/${projectId}/versions.json`)
                    .then(response => response.json())
                    .then(data => {
                        // Очистка и добавление новых опций
                        versionSelect.innerHTML = '<option value=""></option>';
                        data.forEach(version => {
                            const option = document.createElement('option');
                            option.value = version.id;
                            option.textContent = version.name;
                            versionSelect.appendChild(option);
                        });
                    });

                // Загрузка задач
                fetch(`/projects/${projectId}/issues.json`)
                    .then(response => response.json())
                    .then(data => {
                        // Очистка и добавление новых опций
                        issuesSelect.innerHTML = '';
                        data.forEach(issue => {
                            const option = document.createElement('option');
                            option.value = issue.id;
                            option.textContent = issue.subject;
                            issuesSelect.appendChild(option);
                        });
                    });
            } else {
                // Очистка полей, если проект не выбран
                versionSelect.innerHTML = '<option value=""></option>';
                issuesSelect.innerHTML = '';
            }
        });
    }
});

var IssuesSelectHandler = (function() {
    function addIssuesSelectStyles() {
        // Стили остаются без изменений
        const styleElement = document.createElement('style');
        styleElement.textContent = `
            .issues-selection-container .select2-container {
                width: 100% !important;
            }
            .issues-selection-container .select2-container--open {
                z-index: 9999 !important;
            }
            .issues-selection-container .select2-dropdown {
                z-index: 9999 !important;
                position: absolute !important;
                width: auto !important;
                min-width: 100%;
            }
            .issues-selection-container .select2-results {
                display: block !important;
                visibility: visible !important;
                max-height: 300px;
                overflow-y: auto;
            }
            .issues-selection-container .select2-result-issue {
                padding: 4px 0;
            }
            .issues-selection-container .select2-result-issue__id {
                font-weight: bold;
                display: inline-block;
                margin-right: 8px;
            }
            .issues-selection-container .select2-result-issue__title {
                display: inline-block;
            }
            .issues-selection-container .select2-result-issue__project {
                font-size: 0.9em;
                color: #666;
                margin-top: 2px;
            }
        `;
        document.head.appendChild(styleElement);
    }

    function initializeIssuesSelect() {
        console.log('Initializing issues select2...');
        var $issuesSelect = $('#issues-select');

        if (!$issuesSelect.length) return;

        if ($issuesSelect.hasClass('select2-hidden-accessible')) {
            $issuesSelect.select2('destroy');
        }

        // Изменяем настройки select2 для использования стандартных URL Redmine
        $issuesSelect.select2({
            dropdownParent: $('body'),
            width: '100%',
            multiple: true,
            minimumInputLength: 1,
            allowClear: true,
            placeholder: 'Поиск задач по номеру или названию...',
            ajax: {
                type: 'GET',
                dataType: 'json',
                url: function() {
                    var url = $('#issues-select').data('search-url');
                    if (!url.endsWith('.json')) {
                        url += '.json';
                    }
                    return url;
                },
                data: function(params) {
                    return {
                        q: params.term,
                        sort: 'id',
                        direction: 'desc',
                        version_id: $('#version-select').val(),
                        authenticity_token: $('#issues-select').data('auth-token')  // Добавляем токен в параметры
                    };
                },
                headers: {
                    'X-CSRF-Token': $('#issues-select').data('auth-token')  // Добавляем токен в заголовки
                },
                processResults: function(data) {
                    return {
                        results: data.map(function(issue) {
                            return {
                                id: issue.id,
                                text: `#${issue.id} - ${issue.subject}`,
                                subject: issue.subject,
                                project: issue.project
                            };
                        })
                    };
                }
            },
            templateResult: function(issue) {
                if (!issue.id || !issue.text) return issue.text;
                var parts = issue.text.split(' - ');
                return $(
                    '<div class="select2-result-issue">' +
                    '<div class="select2-result-issue__id">' + parts[0] + '</div>' +
                    '<div class="select2-result-issue__title">' + (parts[1] || '') + '</div>' +
                    (issue.project ? '<div class="select2-result-issue__project">' + issue.project + '</div>' : '') +
                    '</div>'
                );
            },
            templateSelection: function(issue) {
                if (!issue.id || !issue.text) return issue.text;
                return issue.text;
            }
        }).on('select2:select', function(e) {
            addIssueToReport(e.params.data.id);
        }).on('select2:unselect', function(e) {
            removeIssueFromReport(e.params.data.id);
        });

        addIssuesSelectStyles();
    }

    // Остальные функции без изменений
    function addIssueToReport(issueId) {
        var reportId = $('#report-form').data('report-id');
        var url = '/registry_reports/' + reportId + '/report_issues/add';

        $.post(url, { issue_id: issueId })
            .fail(function(jqXHR) {
                console.error('Error adding issue:', jqXHR.responseText);
                alert('Ошибка при добавлении задачи');
            });
    }

    function removeIssueFromReport(issueId) {
        var reportId = $('#report-form').data('report-id');
        var url = '/registry_reports/' + reportId + '/report_issues/remove_issue';

        $.ajax({
            url: url,
            type: 'DELETE',
            data: { issue_id: issueId }
        }).fail(function(jqXHR) {
            console.error('Error removing issue:', jqXHR.responseText);
            alert('Ошибка при удалении задачи');
        });
    }

    $(document).on('turbolinks:load ready', function() {
        initializeIssuesSelect();
    });

    $('#project-select, #version-select').on('change', function() {
        initializeIssuesSelect();
    });

    return { initialize: initializeIssuesSelect };
})();
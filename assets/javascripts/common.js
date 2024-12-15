// Общие переменные и функции
var userEditedName = false;

function getFormattedPeriod() {
    const period = $('#report_period').val();
    if (!period) return '';

    let periodValue = '';

    switch (period) {
        case 'месячный':
            const monthSelect = $('#month_select');
            const yearSelect = $('#year_select');
            if (monthSelect.is(':visible') && monthSelect.val() && yearSelect.val()) {
                const monthName = monthSelect.find('option:selected').text();
                periodValue = `${monthName} ${yearSelect.val()}`;
            }
            break;

        case 'квартальный':
            const quarterSelect = $('#quarter_select');
            const yearSelectQ = $('#year_select_q');
            if (quarterSelect.is(':visible') && quarterSelect.val() && yearSelectQ.val()) {
                const quarter = quarterSelect.find('option:selected').text();
                periodValue = `${quarter} ${yearSelectQ.val()}`;
            }
            break;

        case 'годовой':
            const yearSelectY = $('#year_select_y');
            if (yearSelectY.is(':visible') && yearSelectY.val()) {
                periodValue = `${yearSelectY.val()} год`;
            }
            break;

        case 'прочее':
            const startDate = $('#report_start_date').val();
            const endDate = $('#report_end_date').val();
            if (startDate && endDate) {
                periodValue = `${startDate} - ${endDate}`;
            }
            break;
    }

    return periodValue;
}

function updateReportName() {
    if (userEditedName) {
        console.log('Name was edited by user, skipping auto-generation');
        return;
    }

    // Получаем значения полей
    const projectName = $('#project-select option:selected').text().trim();
    const versionName = $('#version-select option:selected').text().trim();
    const periodType = $('#report_period').val();
    const periodValue = getFormattedPeriod();
    const contract = $('#report_contract_number').val().trim();

    // Отладочный вывод
    console.log('Current values:', {
        project: projectName,
        version: versionName,
        periodType: periodType,
        periodValue: periodValue,
        contract: contract
    });

    // Формируем массив компонентов названия
    const components = [
        projectName !== '' ? projectName : null,
        versionName !== '' ? versionName : null,
        periodType || null,
        periodValue || null,
        contract || null
    ].filter(Boolean); // Удаляем пустые значения

    if (components.length > 0) {
        const newName = components.join(' - ');
        console.log('Setting new name:', newName);
        $('#report_name').val(newName);
    }
}

// Добавляем инициализацию select2 для задач
$(document).ready(function () {
    var $issuesSelect = $('#issues-select');

    if ($issuesSelect.length) {
        $issuesSelect.select2({
            width: '100%',
            multiple: true,
            data: $issuesSelect.data('pre'),
            ajax: {
                url: function () {
                    var reportId = $('#report-form').data('report-id');
                    return '/reports/' + reportId + '/report_issues/search';
                },
                dataType: 'json',
                delay: 250,
                data: function (params) {
                    return {
                        q: params.term,
                        page: params.page
                    };
                },
                processResults: function (data, params) {
                    return {
                        results: data.map(function (issue) {
                            return {
                                id: issue.id,
                                text: issue.id + ' - ' + issue.subject
                            };
                        })
                    };
                },
                cache: true
            },
            minimumInputLength: 1,
            templateResult: formatIssue,
            templateSelection: formatIssueSelection
        });
    }
});

var $issuesSelect = $('#issues-select');

if ($issuesSelect.length) {
    $issuesSelect.select2({
        width: '100%',
        multiple: true,
        data: $issuesSelect.data('pre'),
        ajax: {
            url: function() {
                var reportId = $('#report-form').data('report-id');
                return '/reports/' + reportId + '/report_issues/search';
            },
            dataType: 'json',
            delay: 250,
            data: function(params) {
                return {
                    q: params.term,
                    page: params.page
                };
            },
            processResults: function(data, params) {
                return {
                    results: data.map(function(issue) {
                        return {
                            id: issue.id,
                            text: issue.id + ' - ' + issue.subject
                        };
                    })
                };
            },
            cache: true
        },
        minimumInputLength: 1,
        templateResult: formatIssue,
        templateSelection: formatIssueSelection
    });

    // Добавляем обработчик изменений для синхронизации с формой
    $issuesSelect.on('change', function(e) {
        var selectedIds = $(this).val() || [];
        // Обновляем скрытые поля с issue_ids
        $('#report-form').find('input[name="report[issue_ids][]"]').remove();
        selectedIds.forEach(function(id) {
            $('<input>').attr({
                type: 'hidden',
                name: 'report[issue_ids][]',
                value: id
            }).appendTo('#report-form');
        });
    });
}

function formatIssue(issue) {
    if (issue.loading) return issue.text;
    return $('<span>').text(issue.text);
}

function formatIssueSelection(issue) {
    return issue.text;
}

// Инициализация при загрузке страницы
$(document).ready(function () {
    // Обработчик ручного изменения названия
    $('#report_name').on('input', function () {
        userEditedName = true;
        console.log('Name was manually edited');
    });

    // Инициализация начального значения, если форма редактирования
    if ($('#report_name').val()) {
        userEditedName = true;
    }
});
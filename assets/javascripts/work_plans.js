/* assets/javascripts/work_plans.js */

// Инициализация
$(document).ready(function() {
    // Инициализация модальных окон
    initModal();

    // Инициализация выпадающих меню
    initDropdowns();

    // Инициализация обработчиков формы распределения часов
    initHoursDistribution();

    // Инициализация Select2
    initSelect2();
});

// Модальные окна
function initModal() {
    // Открытие модального окна при клике на элементы с data-remote=true
    $(document).on('click', 'a[data-remote="true"]', function(e) {
        e.preventDefault();
        var url = $(this).attr('href');

        $.ajax({
            url: url,
            dataType: 'html',
            success: function(response) {
                $('#modal-window').html(response).show();
                $('.modal-close').click(function() {
                    $('#modal-window').hide().empty();
                    return false;
                });
            }
        });
    });

    // Закрытие модального окна при нажатии ESC
    $(document).keyup(function(e) {
        if (e.keyCode === 27) {
            $('#modal-window').hide().empty();
        }
    });

    // Закрытие модального окна при клике вне его области
    $(document).on('click', function(e) {
        if ($(e.target).closest('#modal-window').length === 0 && $('#modal-window').is(':visible')) {
            $('#modal-window').hide().empty();
        }
    });

    // Предотвращение закрытия окна при клике внутри него
    $(document).on('click', '#modal-window', function(e) {
        e.stopPropagation();
    });
}

// Выпадающие меню - обновлено для новых классов
function initDropdowns() {
    // Показать/скрыть выпадающее меню при клике на его триггер
    $(document).on('click', '.wp-dropdown-toggle', function(e) {
        e.preventDefault();
        e.stopPropagation();

        var $menu = $(this).next('.wp-dropdown-menu');
        $('.wp-dropdown-menu').not($menu).hide();
        $menu.toggle();
    });

    // Скрыть выпадающие меню при клике вне их области
    $(document).on('click', function() {
        $('.wp-dropdown-menu').hide();
    });

    // Предотвращение закрытия меню при клике внутри него
    $(document).on('click', '.wp-dropdown-menu', function(e) {
        e.stopPropagation();
    });

    // Для обратной совместимости со старыми меню
    $(document).on('click', '.dropdown-toggle', function(e) {
        e.preventDefault();
        e.stopPropagation();

        var $menu = $(this).next('.dropdown-menu');
        $('.dropdown-menu').not($menu).hide();
        $menu.toggle();
    });

    $(document).on('click', '.dropdown-menu', function(e) {
        e.stopPropagation();
    });

    // Сначала скрываем все выпадающие меню
    $('.wp-dropdown-menu, .dropdown-menu').hide();
}

// Инициализация Select2
function initSelect2() {
    // Применяем Select2 к выпадающим спискам
    if ($.fn.select2) {
        $('.select2').select2({
            width: '100%',
            allowClear: true
        });

        // Select2 для поиска задач
        $('.issue-select').select2({
            width: '100%',
            minimumInputLength: 1,
            ajax: {
                url: function() {
                    return $(this).data('search-url');
                },
                dataType: 'json',
                delay: 300,
                data: function(params) {
                    return {
                        q: params.term
                    };
                },
                processResults: function(data) {
                    return {
                        results: data
                    };
                },
                cache: true
            },
            templateResult: formatIssue,
            templateSelection: formatIssue
        });
    }
}

// Форматирование задачи для Select2
function formatIssue(issue) {
    if (!issue.id) return issue.text;

    var $result = $('<div class="select2-issue">' +
        '<div class="select2-issue-id">#' + issue.id + '</div>' +
        '<div class="select2-issue-text">' + issue.text + '</div>' +
        '</div>');

    return $result;
}

// Распределение часов по месяцам
function initHoursDistribution() {
    // При изменении часов в одном из месяцев обновляем общую сумму
    $(document).on('change', '.hours-input', function() {
        updateTotalHours();
    });

    // Обновление общей суммы часов
    function updateTotalHours() {
        var total = 0;

        $('.hours-input').each(function() {
            var hours = parseFloat($(this).val()) || 0;
            total += hours;
        });

        $('#total-hours').text(total.toFixed(2));
        $('#work_plan_task_total_hours').val(total);
    }

    // Равномерное распределение часов по месяцам
    $(document).on('click', '#distribute-evenly', function(e) {
        e.preventDefault();

        var totalHours = parseFloat($('#work_plan_task_total_hours').val()) || 0;
        var monthInputs = $('.hours-input:visible');
        var monthCount = monthInputs.length;

        if (monthCount > 0 && totalHours > 0) {
            var hoursPerMonth = (totalHours / monthCount).toFixed(2);

            monthInputs.each(function() {
                $(this).val(hoursPerMonth);
            });

            updateTotalHours();
        }
    });

    // Обнуление всех часов
    $(document).on('click', '#reset-hours', function(e) {
        e.preventDefault();

        $('.hours-input').each(function() {
            $(this).val('0');
        });

        updateTotalHours();
    });
}

// Обработка AJAX форм
$(document).on('submit', 'form[data-remote="true"]', function(e) {
    e.preventDefault();

    var form = $(this);
    var url = form.attr('action');
    var method = form.attr('method') || 'post';
    var data = form.serialize();

    $.ajax({
        url: url,
        method: method,
        data: data,
        dataType: 'script',
        success: function(response) {
            // Закрываем модальное окно после успешного сохранения
            if (form.hasClass('close-modal')) {
                $('#modal-window').hide().empty();
            }
        }
    });
});

// Удаление элементов через AJAX
$(document).on('click', 'a.icon-del[data-remote="true"]', function(e) {
    e.preventDefault();

    if (!confirm($(this).data('confirm') || 'Are you sure?')) {
        return false;
    }

    var link = $(this);
    var url = link.attr('href');

    $.ajax({
        url: url,
        method: 'DELETE',
        dataType: 'script',
        success: function(response) {
            // По умолчанию предполагаем, что скрипт обновит DOM
        }
    });
});
// # plugins/report_registry/assets/javascripts/report_menu.js
var ReportMenu = (function() {
    function init() {
        initializeEventHandlers();
    }

    function initializeEventHandlers() {
        // Обработчик клика по кнопке добавления
        $(document).on('click', '#show-report-menu', function(e) {
            e.preventDefault();
            e.stopPropagation();
            showMenu(this);
        });

        // Обработчик клика по пункту меню
        $(document).on('click', '.add-report-link', function(e) {
            e.preventDefault();
            e.stopPropagation();
            addReportToIssue(this);
        });

        // Закрытие меню при клике вне его
        $(document).on('click', function(e) {
            if (!$(e.target).closest('#report-menu, #show-report-menu').length) {
                $('#report-menu').hide();
            }
        });
    }

    function showMenu(link) {
        var menu = $('#report-menu');
        var $link = $(link);
        var offset = $link.offset();
        var linkHeight = $link.outerHeight();

        // Проверяем, есть ли место ниже кнопки
        var spaceBelow = $(window).height() - (offset.top + linkHeight);
        var menuHeight = menu.outerHeight();

        var top;
        if (spaceBelow >= menuHeight || spaceBelow >= 100) {
            // Размещаем меню под кнопкой
            top = offset.top + linkHeight;
        } else {
            // Размещаем меню над кнопкой
            top = offset.top - menuHeight;
        }

        menu.css({
            position: 'absolute',
            top: top + 'px',
            left: offset.left + 'px',
            zIndex: 1000
        }).show();

        // Убеждаемся, что меню полностью видно
        if (menu.offset().top + menu.outerHeight() > $(window).height()) {
            menu.css('top', $(window).height() - menu.outerHeight() - 10);
        }
    }

    function addReportToIssue(link) {
        var $link = $(link);
        var url = $link.attr('href');
        var reportId = $link.data('report-id');

        if (!reportId) {
            console.error('Report ID is missing!');
            alert('Не удалось определить ID отчета.');
            return;
        }

        $.ajax({
            url: url,
            method: 'POST',
            data: { report_id: reportId },
            dataType: 'script',
            beforeSend: function(xhr) {
                xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'));
            },
            success: function() {
                $('#report-menu').hide();
            },
            error: function(xhr, status, error) {
                console.error('Error adding report:', error);
                alert('Произошла ошибка при добавлении отчета');
            }
        });
    }

    // Публичное API
    return {
        init: init,
        showMenu: showMenu
    };
})();

// Инициализация при загрузке документа
$(document).ready(function() {
    ReportMenu.init();
});
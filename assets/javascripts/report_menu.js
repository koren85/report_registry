// assets/javascripts/report_menu.js
var ReportMenu = (function() {
    function init() {
        initializeEventHandlers();
    }

    function initializeEventHandlers() {
        // Обработчик клика по кнопке добавления
        $(document).on('click', '#show-report-menu', function(e) {
            e.preventDefault();
            showMenu(this);
        });

        // Обработчик клика по пункту меню
        $(document).on('click', '.add-report-link', function(e) {
            e.preventDefault();
            addReportToIssue(this);
        });

        // Обработчик для добавления отчета через модальное окно
        $(document).on('click', '#add-report', function(e) {
            e.preventDefault();
            var url = $(this).data('url');

            $.ajax({
                url: url,
                type: 'GET',
                dataType: 'script',
                success: function() {
                    $('#reports-modal').show();
                }
            });
        });

        // Закрытие модального окна
        $(document).on('click', '.close-modal', function(e) {
            e.preventDefault();
            $('#reports-modal').hide();
        });

        // Закрытие модального окна при клике вне его
        $(document).on('click', function(e) {
            if ($('#reports-modal').is(':visible') && !$(e.target).closest('.modal-content').length) {
                $('#reports-modal').hide();
            }
        });

        // Обработчик удаления отчета
        $(document).on('ajax:success', '.delete-report', function() {
            $(this).closest('.report').fadeOut();
        });
    }

    function showMenu(link) {
        var menu = $('#report-menu');
        var position = $(link).offset();

        menu.css({
            top: position.top + $(link).outerHeight(),
            left: position.left
        }).show();

        // Закрытие меню при клике вне его
        $(document).on('click', function closeMenu(e) {
            if (!$(e.target).closest('#report-menu, #show-report-menu').length) {
                menu.hide();
                $(document).off('click', closeMenu);
            }
        });
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
                // Обновляем список отчетов после успешного добавления
                if (typeof updateReportsList === 'function') {
                    updateReportsList();
                }
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
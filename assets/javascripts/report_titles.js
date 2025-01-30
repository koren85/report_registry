// plugins/report_registry/assets/javascripts/report_titles.js

function initializeReportTitles() {
    // Функция для автоматической подстройки высоты
    function autoResizeTextarea(textarea) {
        textarea.style.height = 'auto';
        textarea.style.height = (textarea.scrollHeight) + 'px';
    }

    // Применяем авторазмер ко всем полям при загрузке
    $('.report-title-field').each(function() {
        autoResizeTextarea(this);
    });

    // Обновляем размер при вводе текста
    $(document).off('input', '.report-title-field').on('input', '.report-title-field', function() {
        autoResizeTextarea(this);
    });

    // Сохраняем предыдущее значение при фокусе
    $(document).off('focus', '.report-title-field').on('focus', '.report-title-field', function() {
        $(this).data('previous-value', $(this).val());
    });

    // Обработчик изменения названия задачи
    // В файле report_titles.js

// Обработчик изменения названия задачи
    $(document).off('change', '.report-title-field').on('change', '.report-title-field', function() {
        var $field = $(this);
        var newValue = $field.val();
        var previousValue = $field.data('previous-value');
        var url = $field.data('url');

        // Если значение не изменилось, не делаем ничего
        if (newValue === previousValue) {
            return;
        }

        // Запрашиваем подтверждение изменений
        if (!confirm('Вы хотите сохранить изменения в названии задачи?')) {
            $field.val(previousValue); // Возвращаем предыдущее значение
            return;
        }

        // Получаем ID из атрибутов
        var issueReportId = $field.data('issue-report-id');

        $.ajax({
            url: url,
            type: 'PATCH',
            data: {
                report_title: newValue
            },
            headers: {
                'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
            },
            dataType: 'json',
            success: function(response) {
                // Обновляем previous-value в случае успеха
                $field.data('previous-value', newValue);
                // Добавляем эффект подсветки для индикации успешного сохранения
                $field.closest('td').effect('highlight', {}, 1000);
                // Показываем уведомление об успехе
                showNotification('success', 'Название задачи успешно обновлено');
            },
            error: function(xhr) {
                // Возвращаем предыдущее значение в случае ошибки
                $field.val(previousValue);
                // Показываем сообщение об ошибке
                showNotification('error', xhr.responseJSON?.error || 'Ошибка при обновлении названия');
            }
        });
    });

    // Функция для отображения уведомлений
    function showNotification(type, message) {
        var className = type === 'success' ? 'notice' : 'error';
        var $notification = $('<div class="flash ' + className + '">')
            .text(message)
            .hide()
            .prependTo('#content')
            .fadeIn();

        setTimeout(() => $notification.fadeOut(() => $notification.remove()), 3000);
    }
}

// Инициализация при загрузке страницы
$(document).ready(function() {
    initializeReportTitles();
});

// Реинициализация после AJAX запросов
$(document).ajaxComplete(function(event, xhr, settings) {
    if (settings.url.includes('add_issues') ||
        settings.url.includes('modal_issues') ||
        settings.url.includes('remove_issue')) {
        setTimeout(initializeReportTitles, 100);
    }
});

// Делаем функцию доступной глобально
window.initializeReportTitles = initializeReportTitles;
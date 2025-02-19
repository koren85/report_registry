// plugins/report_registry/assets/javascripts/report_hours.js

function initializeHoursHandling() {
    // Сохраняем предыдущее значение при фокусе
    $(document).off('focus', '.reported-hours-field').on('focus', '.reported-hours-field', function() {
        $(this).data('previous-value', $(this).val());
    });

    // Обработчик изменения часов
    $(document).off('change', '.reported-hours-field').on('change', '.reported-hours-field', function() {
        var $field = $(this);
        var newValue = $field.val();
        var previousValue = $field.data('previous-value');
        var url = $field.data('url');

        // Если значение не изменилось, не делаем ничего
        if (newValue === previousValue) {
            return;
        }

        // Базовая валидация
        if (isNaN(newValue) || parseFloat(newValue) < 0) {
            alert('Значение должно быть положительным числом');
            $field.val(previousValue);
            return;
        }

        // Запрашиваем подтверждение изменений
        if (!confirm('Вы хотите сохранить изменения?')) {
            $field.val(previousValue); // Возвращаем предыдущее значение
            return;
        }

        // Получаем ID из атрибутов
        var issueReportId = $field.data('issue-report-id');

        // Отправляем AJAX запрос
        $.ajax({
            url: url,
            type: 'PATCH',
            data: {
                reported_hours: newValue
            },
            headers: {
                'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
            },
            dataType: 'script',
            success: function(response) {
                // Обновляем previous-value в случае успеха
                $field.data('previous-value', newValue);
                // Добавляем эффект подсветки для индикации успешного сохранения
                $field.closest('td').effect('highlight', {}, 1000);
                // Показываем уведомление об успехе
                showNotification('success', 'Количество часов успешно обновлено');
            },
            error: function(xhr) {
                // Возвращаем предыдущее значение в случае ошибки
                $field.val(previousValue);
                // Показываем сообщение об ошибке
                showNotification('error', xhr.responseJSON?.error || 'Ошибка при обновлении часов');
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
    initializeHoursHandling();
});

// Реинициализация после AJAX запросов
$(document).ajaxComplete(function(event, xhr, settings) {
    if (settings.url.includes('add_issues') ||
        settings.url.includes('modal_issues') ||
        settings.url.includes('remove_issue')) {
        setTimeout(initializeHoursHandling, 100);
    }
});

// Делаем функцию доступной глобально
window.initializeHoursHandling = initializeHoursHandling;
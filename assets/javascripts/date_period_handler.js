$(document).ready(function() {
    // DOM элементы - кэшируем все jQuery объекты
    const $periodSelect = $('#report_period');
    const $monthlyFields = $('#monthly_fields');
    const $quarterlyFields = $('#quarterly_fields');
    const $yearlyFields = $('#yearly_fields');
    const $customDateFields = $('#custom_date_fields');
    const $contractInput = $('#report_contract_number');

    const $monthSelect = $('#month_select');
    const $quarterSelect = $('#quarter_select');
    const $yearSelects = $('.period-select[id^="year_select"]');

    const $hiddenStartDate = $('#hidden_start_date');
    const $hiddenEndDate = $('#hidden_end_date');
    const $startDate = $('#report_start_date');
    const $endDate = $('#report_end_date');

    // Добавляем ссылки на скрытые поля для сохранения выбранных значений
    const $selectedMonthField = $('#selected_month_field');
    const $selectedQuarterField = $('#selected_quarter_field');
    const $selectedYearField = $('#selected_year_field');

    // Функция инициализации полей дат
    function initializeDateFields() {
        const period = $periodSelect.val();

        // Скрываем все поля
        $monthlyFields.hide();
        $quarterlyFields.hide();
        $yearlyFields.hide();
        $customDateFields.hide();

        // Показываем нужные поля
        switch(period) {
            case 'месячный':
                $monthlyFields.show();
                break;
            case 'квартальный':
                $quarterlyFields.show();
                break;
            case 'годовой':
                $yearlyFields.show();
                break;
            case 'прочее':
                $customDateFields.show();
                break;
        }

        // Инициализируем значения из сохраненных полей
        initializeFromSavedValues();
        updateHiddenDates();
        updateReportName(); // Обновляем название при инициализации
    }

    // Обработчики событий
    $periodSelect.on('change', function() {
        initializeDateFields();
    });

    // Обработчики для всех селектов периода
    $('.period-select').on('change', function() {
        updateHiddenDates();
        updateReportName();
    });

    // Обработчик для номера контракта
    $contractInput.on('input', function() {
        updateReportName();
    });

    // Обработчики для полей дат
    $startDate.add($endDate).on('change', function() {
        updateHiddenDates();
        updateReportName();
    });

    // Обновить скрытые поля сохраненных значений при изменении
    $monthSelect.on('change', function() {
        $selectedMonthField.val($(this).val());
    });

    $quarterSelect.on('change', function() {
        $selectedQuarterField.val($(this).val());
    });

    $('#year_select, #year_select_q, #year_select_y').on('change', function() {
        $selectedYearField.val($(this).val());
    });

    // Вспомогательные функции
    function getLastDayOfMonth(year, month) {
        return new Date(year, month, 0).getDate();
    }

    function formatDate(date) {
        return date.toISOString().split('T')[0];
    }

    // Функция обновления скрытых полей дат
    function updateHiddenDates() {
        const period = $periodSelect.val();
        let year, month, quarter;

        // Получаем выбранные значения
        if (period === 'месячный') {
            month = parseInt($monthSelect.val());
            year = parseInt($('#year_select').val());
            // Сохраняем выбранные значения
            $selectedMonthField.val(month);
            $selectedYearField.val(year);
        } else if (period === 'квартальный') {
            quarter = parseInt($quarterSelect.val());
            year = parseInt($('#year_select_q').val());
            // Сохраняем выбранные значения
            $selectedQuarterField.val(quarter);
            $selectedYearField.val(year);
        } else if (period === 'годовой') {
            year = parseInt($('#year_select_y').val());
            // Сохраняем выбранное значение
            $selectedYearField.val(year);
        }

        let startDate, endDate;

        switch(period) {
            case 'месячный':
                const month = parseInt($monthSelect.val());
                if (year && month) {
                    startDate = new Date(year, month - 1, 1);
                    endDate = new Date(year, month - 1, getLastDayOfMonth(year, month));
                }
                break;

            case 'квартальный':
                const quarter = parseInt($quarterSelect.val());
                if (year && quarter) {
                    startDate = new Date(year, (quarter - 1) * 3, 1);
                    endDate = new Date(year, quarter * 3 - 1, getLastDayOfMonth(year, quarter * 3));
                }
                break;

            case 'годовой':
                if (year) {
                    startDate = new Date(year, 0, 1);
                    endDate = new Date(year, 11, 31);
                }
                break;

            case 'прочее':
                startDate = $startDate.val() ? new Date($startDate.val()) : null;
                endDate = $endDate.val() ? new Date($endDate.val()) : null;
                break;
        }

        if (startDate && endDate) {
            // Обновляем скрытые поля и видимые поля даты
            const formattedStartDate = typeof startDate === 'string' ? startDate : formatDate(startDate);
            const formattedEndDate = typeof endDate === 'string' ? endDate : formatDate(endDate);

            $hiddenStartDate.val(formattedStartDate);
            $hiddenEndDate.val(formattedEndDate);

            // Также обновляем видимые поля даты, если это не тип "прочее"
            if (period !== 'прочее') {
                $startDate.val(formattedStartDate);
                $endDate.val(formattedEndDate);
            }

            console.log('Updated dates: ', formattedStartDate, formattedEndDate);
        }
    }

    // Добавляем обработчик отправки формы
    $('#report-form').on('submit', function() {
        // Принудительно обновляем даты перед отправкой
        updateHiddenDates();
        return true;
    });

    // Предзаполняем поля выбора периода на основе существующих дат
    function initializeFromExistingDates() {
        const startDate = $hiddenStartDate.val();
        const endDate = $hiddenEndDate.val();
        const period = $periodSelect.val();

        if (startDate && endDate && period) {
            const start = new Date(startDate);
            const end = new Date(endDate);

            const startYear = start.getFullYear();
            const startMonth = start.getMonth() + 1;

            switch(period) {
                case 'месячный':
                    $('#year_select').val(startYear);
                    $('#month_select').val(startMonth);
                    break;
                case 'квартальный':
                    const quarter = Math.floor((startMonth - 1) / 3) + 1;
                    $('#year_select_q').val(startYear);
                    $('#quarter_select').val(quarter);
                    break;
                case 'годовой':
                    $('#year_select_y').val(startYear);
                    break;
            }
        }
    }

    // Новая функция для инициализации из сохраненных значений
    function initializeFromSavedValues() {
        const period = $periodSelect.val();
        const selectedMonth = $selectedMonthField.val();
        const selectedQuarter = $selectedQuarterField.val();
        const selectedYear = $selectedYearField.val();

        if (period && selectedYear) {
            switch(period) {
                case 'месячный':
                    if (selectedMonth) {
                        $('#month_select').val(selectedMonth);
                        $('#year_select').val(selectedYear);
                    }
                    break;
                case 'квартальный':
                    if (selectedQuarter) {
                        $('#quarter_select').val(selectedQuarter);
                        $('#year_select_q').val(selectedYear);
                    }
                    break;
                case 'годовой':
                    $('#year_select_y').val(selectedYear);
                    break;
            }
        } else {
            // Если нет сохраненных значений, используем дефолтные
            initializeFromExistingDates();
        }
    }

    // Запускаем инициализацию при загрузке
    initializeDateFields();

});
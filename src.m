classdef WeatherScope < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                 matlab.ui.Figure
        WindSpeedLabel           matlab.ui.control.Label
        HumiditiyLabel           matlab.ui.control.Label
        TemperatureLabel         matlab.ui.control.Label
        GetInformationButton     matlab.ui.control.Button
        SelectCityDropDown       matlab.ui.control.DropDown
        SelectCityDropDownLabel  matlab.ui.control.Label
        AddCityButton            matlab.ui.control.Button
        EditField                matlab.ui.control.EditField
        windSpeedAxes            matlab.ui.control.UIAxes
        humidityAxes             matlab.ui.control.UIAxes
        TemperatureAxes          matlab.ui.control.UIAxes
    end

    
    methods (Access = private)
        
        function response = fetchFiveDayForecast(app, city)
            
            % We are creating an API url.
            apiKey = '7d8e351c27677eb71f1154f648181a0e';
            url = 'http://api.openweathermap.org/data/2.5/forecast';
            query = sprintf('?q=%s&appid=%s&units=metric', city, apiKey);
            url = [url query];

            % We call data from API. If it is fails, throws excepiton.
            try
                response = webread(url);
            catch excepiton
                error('API isteği başarısız oldu: %s', excepiton.message);
            end
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: AddCityButton
        function AddCityButtonPushed(app, event)
         
            newCity = app.EditField.Value;            
            app.SelectCityDropDown.Items{end+1} = newCity;
            app.EditField.Value = '';

        end

        % Button pushed function: GetInformationButton
        function GetInformationButtonPushed(app, event)

            % Getting the necessary data from the struct() structure
            city = app.SelectCityDropDown.Value;
            forecast = fetchFiveDayForecast(app, city);
            temp = forecast.list{1,1}.main.temp;
            humidity = forecast.list{1,1}.main.humidity;
            wind_speed = forecast.list{1,1}.wind.speed;
            
            % Updating Labels by cities.
            app.TemperatureLabel.Text = sprintf('Temperature:  %.2f°C', temp);
            app.HumiditiyLabel.Text = sprintf('Humidity:  %d%%', humidity);
            app.WindSpeedLabel.Text = sprintf('Wind Speed: %.2f m/s', wind_speed);

            % We assigned temperature, humidity and wind speed information to the arrays.
            tempArray = [];
            humidityArray = [];
            windSpeedArray = [];
            dateArray = [];

            for i = 1:length(forecast.list)
                tempArray = [tempArray, forecast.list{i}.main.temp];
                humidityArray = [humidityArray, forecast.list{i}.main.humidity];
                windSpeedArray = [windSpeedArray, forecast.list{i}.wind.speed];
                dateArray = [dateArray, {forecast.list{i}.dt_txt}];
            end
            
            %We converted date information to datetime format
            dateArray = datetime(dateArray, 'InputFormat', 'yyyy-MM-dd HH:mm:ss');

            % we found unique days i.e. days of the week
            days = unique(dateshift(dateArray, 'start', 'day'));
            
            % We calculated temperature, humidity and wind speed for each day.
            dailyTemp = zeros(size(days));
            dailyHumidity = zeros(size(days));
            dailyWindSpeed = zeros(size(days));
            
            for i = 1:length(days)
                checkDay = dateshift(dateArray, 'start', 'day') == days(i);
                dailyTemp(i) = mean(tempArray(checkDay));
                dailyHumidity(i) = mean(humidityArray(checkDay));
                dailyWindSpeed(i) = mean(windSpeedArray(checkDay));
            end
            
            % We assigned the average values ​​we found
            weatherData.Temperature = dailyTemp;
            weatherData.Humidity = dailyHumidity;
            weatherData.WindSpeed = dailyWindSpeed;
            weatherData.Dates = days;

            % We called the interp1 method to make the graph look more smooth.
            dates = linspace(min(weatherData.Dates), max(weatherData.Dates), 10);
            temp = interp1(weatherData.Dates, weatherData.Temperature, dates, 'spline');
            humidity = interp1(weatherData.Dates, weatherData.Humidity, dates, 'spline');
            windSpeed =  interp1(weatherData.Dates, weatherData.WindSpeed, dates, 'spline');

            % Update Temperature Graph
            plot(app.TemperatureAxes, dates, temp, '-o');
            title(app.TemperatureAxes, ['Temperature Forecast for ', app.SelectCityDropDown.Value]);
            xlabel(app.TemperatureAxes, 'Date');
            ylabel(app.TemperatureAxes, 'Temperature (°C)');
            
            % Update Humidity Graph
            plot(app.humidityAxes, dates, humidity, '-x');
            title(app.humidityAxes, ['Humidity Forecast for ', app.SelectCityDropDown.Value]);
            xlabel(app.humidityAxes, 'Date');
            ylabel(app.humidityAxes, 'Humidity (%)');
            
            % Update Wind Speed Graph
            plot(app.windSpeedAxes, dates, windSpeed, '-+');
            title(app.windSpeedAxes, ['Wind Speed Forecast for ', app.SelectCityDropDown.Value]);
            xlabel(app.windSpeedAxes, 'Date');
            ylabel(app.windSpeedAxes, 'Wind Speed (m/s)');
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Color = [0.902 0.902 0.902];
            app.UIFigure.Position = [100 100 640 480];
            app.UIFigure.Name = 'MATLAB App';

            % Create TemperatureAxes
            app.TemperatureAxes = uiaxes(app.UIFigure);
            title(app.TemperatureAxes, 'Temperature')
            xlabel(app.TemperatureAxes, 'Date')
            ylabel(app.TemperatureAxes, 'Temperature (°C)')
            zlabel(app.TemperatureAxes, 'Z')
            app.TemperatureAxes.Position = [1 296 208 162];

            % Create humidityAxes
            app.humidityAxes = uiaxes(app.UIFigure);
            title(app.humidityAxes, 'Humidity')
            xlabel(app.humidityAxes, 'Date')
            ylabel(app.humidityAxes, 'Humidity (%)')
            zlabel(app.humidityAxes, 'Z')
            app.humidityAxes.Position = [208 296 208 162];

            % Create windSpeedAxes
            app.windSpeedAxes = uiaxes(app.UIFigure);
            title(app.windSpeedAxes, 'Wind Speed')
            xlabel(app.windSpeedAxes, 'Date')
            ylabel(app.windSpeedAxes, 'Wind Speed (m/s)')
            zlabel(app.windSpeedAxes, 'Z')
            app.windSpeedAxes.Position = [423 296 208 162];

            % Create EditField
            app.EditField = uieditfield(app.UIFigure, 'text');
            app.EditField.Position = [126 222 100 22];

            % Create AddCityButton
            app.AddCityButton = uibutton(app.UIFigure, 'push');
            app.AddCityButton.ButtonPushedFcn = createCallbackFcn(app, @AddCityButtonPushed, true);
            app.AddCityButton.Position = [234 222 100 23];
            app.AddCityButton.Text = 'Add City';

            % Create SelectCityDropDownLabel
            app.SelectCityDropDownLabel = uilabel(app.UIFigure);
            app.SelectCityDropDownLabel.HorizontalAlignment = 'right';
            app.SelectCityDropDownLabel.Position = [369 222 66 22];
            app.SelectCityDropDownLabel.Text = 'Select City:';

            % Create SelectCityDropDown
            app.SelectCityDropDown = uidropdown(app.UIFigure);
            app.SelectCityDropDown.Items = {};
            app.SelectCityDropDown.Position = [450 222 100 22];
            app.SelectCityDropDown.Value = {};

            % Create GetInformationButton
            app.GetInformationButton = uibutton(app.UIFigure, 'push');
            app.GetInformationButton.ButtonPushedFcn = createCallbackFcn(app, @GetInformationButtonPushed, true);
            app.GetInformationButton.Position = [271 85 100 23];
            app.GetInformationButton.Text = 'Get Information';

            % Create TemperatureLabel
            app.TemperatureLabel = uilabel(app.UIFigure);
            app.TemperatureLabel.Position = [83 145 170 22];
            app.TemperatureLabel.Text = 'Temperature: ';

            % Create HumiditiyLabel
            app.HumiditiyLabel = uilabel(app.UIFigure);
            app.HumiditiyLabel.Position = [296 145 106 22];
            app.HumiditiyLabel.Text = 'Humiditiy: ';

            % Create WindSpeedLabel
            app.WindSpeedLabel = uilabel(app.UIFigure);
            app.WindSpeedLabel.Position = [456 145 175 22];
            app.WindSpeedLabel.Text = 'Wind Speed: ';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = WeatherScope

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end

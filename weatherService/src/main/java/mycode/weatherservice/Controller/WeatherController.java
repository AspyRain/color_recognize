package mycode.weatherservice.Controller;

import com.alibaba.fastjson2.JSON;
import com.alibaba.fastjson2.JSONObject;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.http.ResponseEntity;
import org.springframework.web.client.RestTemplate;

@RestController
@RequestMapping("/weather")
public class WeatherController {

    private static final String API_KEY = "aa25dbe4d279055d99a3d41fa91b7326";

    @GetMapping("/getTemp")
    public int getTemp() {
        RestTemplate restTemplate = new RestTemplate();
        String url = "https://api.openweathermap.org/data/2.5/weather?q=" + "chongqing" + "&appid=" + API_KEY;
        ResponseEntity<String> response = restTemplate.getForEntity(url, String.class);

        if (response.getStatusCode().is2xxSuccessful()) {
            String body = response.getBody();
            // 调用修改后的parseWeatherData方法
            return parseWeatherDataToInt8bit(body);
        } else {
            return 0;
        }
    }

    private int parseWeatherDataToInt8bit(String jsonData) {
        try {
            JSONObject response = JSON.parseObject(jsonData);
            JSONObject main = response.getJSONObject("main");
            String temp = main.getString("temp");
            double tempDouble = Double.parseDouble(temp);
            // 将开尔文温度转换为摄氏度，并取整数部分
            int tempInt = (int) (tempDouble - 273.15);

            // 将整数转换为8位二进制数据
            String binaryString = Integer.toBinaryString(tempInt);
            // 确保二进制字符串为8位
            while (binaryString.length() < 8) {
                binaryString = "0" + binaryString;
            }

            // 将二进制字符串转换回整数
            return Integer.parseInt(binaryString, 2);
        } catch (Exception e) {
            e.printStackTrace();
        }
        return 0;
    }
}
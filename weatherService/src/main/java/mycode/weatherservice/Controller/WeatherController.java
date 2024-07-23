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
    public static byte[] getTemp() {
        System.out.println("方法被调用");
        RestTemplate restTemplate = new RestTemplate();
        String url = "https://api.openweathermap.org/data/2.5/weather?q=" + "chongqing" + "&appid=" + API_KEY;
        ResponseEntity<String> response = restTemplate.getForEntity(url, String.class);

        if (response.getStatusCode().is2xxSuccessful()) {
            String body = response.getBody();
            return parseWeatherDataToInt8bit(body);
        } else {
            return null;
        }
    }

    private static byte[] parseWeatherDataToInt8bit(String jsonData) {
        try {
            JSONObject response = JSON.parseObject(jsonData);
            JSONObject main = response.getJSONObject("main");
            String temp = main.getString("temp");
            double tempDouble = Double.parseDouble(temp);
            // 将开尔文温度转换为摄氏度，并取整数部分
            int tempInt = (int) (tempDouble - 273.15);

            // 将整数转换为8位二进制数据
            String binaryString = Integer.toBinaryString(tempInt);

            // 将二进制字符串转换回整数
            return convertBinaryStringToByteArr(binaryString);
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    public static byte[] convertBinaryStringToByteArr(String binaryStr) {
        if (binaryStr.length() > 16) {
            throw new IllegalArgumentException("Binary string exceeds 16 bits.");
        }

        // 补齐至16位
        String paddedBinaryStr = String.format("%16s", binaryStr).replace(' ', '0');

        // 将二进制字符串转换为字节
        int intValue = Integer.parseInt(paddedBinaryStr, 2); // 转换为整数
        System.out.println(intValue);
        byte[] bytes = new byte[2]; // 由于Java中byte为有符号，-128~127，因此2个字节足够表示16位
        bytes[0] = (byte) (intValue >> 8); // 高位字节
        bytes[1] = (byte) intValue; // 低位字节

        return bytes;
    }
}
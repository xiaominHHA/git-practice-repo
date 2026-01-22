package com.example.demo.dto;

import lombok.Data;
import com.fasterxml.jackson.annotation.JsonAutoDetect;

@Data
@JsonAutoDetect(fieldVisibility = JsonAutoDetect.Visibility.ANY)
public class LoginRequest {
    private String username;
    private String password;
}

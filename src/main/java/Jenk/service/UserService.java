package Jenk.service;


import Jenk.dto.LoginRequest;
import Jenk.dto.RegisterUserRequest;
import Jenk.response.LoginResponse;
import Jenk.response.RegisterUserResponse;

public interface UserService {
    RegisterUserResponse registerUser(RegisterUserRequest registerUserRequest);

    LoginResponse login(LoginRequest loginRequest);
}

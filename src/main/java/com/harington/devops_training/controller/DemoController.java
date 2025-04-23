package com.harington.devops_training.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class DemoController {

    @GetMapping("/public")
    public String publicEndpoint() {
        return "Ceci est public !";
    }

    @GetMapping("/private")
    public String privateEndpoint() {
        return "Ceci est privé !";
    }
}
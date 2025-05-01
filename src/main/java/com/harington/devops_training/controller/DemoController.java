package com.harington.devops_training.controller;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.view.RedirectView;

@RestController
public class DemoController {

    @Value("${db.password:defaultPwd}")
    private String dbPassword;

    @GetMapping("/")
    public String home() {
        return "Application OK";  // Réponse directe 200
    }

    @GetMapping("/public")
    public String publicEndpoint() {
        return "Vault DB Password: " + dbPassword;
    }

    @GetMapping("/private")
    public String privateEndpoint() {
        return "Ceci est privé !";
    }
}
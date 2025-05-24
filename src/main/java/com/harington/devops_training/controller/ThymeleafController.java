package com.harington.devops_training.controller;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class ThymeleafController {
    @GetMapping("/welcome")
    public String welcome(Model model) {
        model.addAttribute("message", "This is a Thymeleaf-powered page!");
        return "index";
    }
}

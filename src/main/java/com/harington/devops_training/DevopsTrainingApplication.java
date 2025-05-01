package com.harington.devops_training;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class DevopsTrainingApplication implements CommandLineRunner {
	@Value("${db.password:defaultPwd}")
	private String dbPassword;

	public static void main(String[] args) {
		SpringApplication.run(DevopsTrainingApplication.class, args);
	}

	@Override
	public void run(String... args) throws Exception {
		System.out.println("Vault DB Password from runner: " + dbPassword);
	}
}

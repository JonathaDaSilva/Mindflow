package br.com.mindflow;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@EnableScheduling
@SpringBootApplication
public class MindflowApiApplication {

	public static void main(String[] args) {
		SpringApplication.run(MindflowApiApplication.class, args);
	}
}
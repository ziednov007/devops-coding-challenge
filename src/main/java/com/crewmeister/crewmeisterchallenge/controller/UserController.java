package com.crewmeister.crewmeisterchallenge.controller;

import com.crewmeister.crewmeisterchallenge.model.User;
import com.crewmeister.crewmeisterchallenge.repository.UserRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class UserController {

  private static final Logger log = LoggerFactory.getLogger(UserController.class);

  UserRepository userRepository;

  public UserController(UserRepository userRepository) {
    this.userRepository = userRepository;
  }

  @GetMapping( "/user")
  public String hello(@RequestParam Long id) {
    log.info("GET /user id={}", id);
    User user = userRepository.findById(id);
    log.info("GET /user returning name={}", user.getName());
    return "Greetings from Crewmeister, " + user.getName() + "!";
  }

  @PostMapping( "/user")
  public String helloPost(@RequestBody String body) {
    try {
      ObjectMapper objectMapper = new ObjectMapper();
      JsonNode jsonNode = objectMapper.readTree(body);
      String name = jsonNode.get("name").asText();
      log.info("POST /user name={}", name);

      User user = new User();
      user.setName(name);
      User returnedUser = userRepository.save(user);

      log.info("POST /user created id={}", returnedUser.getId());
      return "Greetings from Crewmeister, " + returnedUser.getName() + "!";
    } catch (Exception e) {
      log.error("POST /user failed to parse body", e);
      return "Error parsing JSON";
    }
  }

}

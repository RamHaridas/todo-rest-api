import {
    Body,
    Controller,
    Post,
    Put,
    UsePipes,
    ValidationPipe,
    } from '@nestjs/common';
import { UserService } from './user.service';
import { CreateUserDto } from './dto/create-User.dto';
    
    @Controller('user')
    export class UserController {
      constructor(private readonly userService: UserService) {}
      
      @Post('register')
      @UsePipes(ValidationPipe)
      createUsers(@Body() createUserDto: CreateUserDto) {
        return this.userService.createUser(createUserDto);
      }

      @Put('login')
      loginUser(@Body() createUserDto: CreateUserDto) {
        var payload = this.userService.findUserbyUsernameAndPassword(createUserDto);
        console.log(payload)
        return payload;
      }
    }

import { IsEmail, IsNotEmpty, MinLength } from "class-validator";

export class CreateUserDto {

  @IsNotEmpty()
  @MinLength(3)
  password: string;

  @IsNotEmpty()
  @IsEmail()
  email: string;
}
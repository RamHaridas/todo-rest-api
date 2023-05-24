import { Injectable, UnauthorizedException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { UserEntity } from 'src/typeorm';
import { Repository } from 'typeorm';
import { CreateUserDto } from './dto/create-User.dto';
import { JwtService } from '@nestjs/jwt';

@Injectable()
export class UserService {
  constructor(
    @InjectRepository(UserEntity) private readonly userRepository: Repository<UserEntity>,
    private jwtservice: JwtService,
  ) {}
      
  createUser(createUserDto: CreateUserDto ) {
    const newUser = this.userRepository.create(createUserDto);
    return this.userRepository.save(newUser);
  }
      
  async findUserbyUsernameAndPassword(createUserDto: CreateUserDto ){
    const payload = await this.userRepository.findOneBy(createUserDto);
    if (!payload){
      return {"msg":"Invalid username/password"};
    }
    const jwtpayload = { sub: payload.id, username: payload.email };
    console.log(process.env.JWT_SECRET)
    return {
        access_token: this.jwtservice.sign(jwtpayload,{secret:process.env.JWT_SECRET, expiresIn:'10h'})
    };
  }
}
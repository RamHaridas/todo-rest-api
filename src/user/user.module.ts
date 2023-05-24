import { Module } from '@nestjs/common';
import { UserController } from './user.controller';
import { UserService } from './user.service';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UserEntity } from 'src/typeorm';
import { JwtModule, JwtService } from '@nestjs/jwt';

@Module({
  imports:[
  TypeOrmModule.forFeature([UserEntity]),
  JwtModule.register({
    global: true,
    secretOrPrivateKey: process.env.JWT_SECRET,
    signOptions: { expiresIn: '10h' },
  }),
],
  controllers: [UserController],
  providers: [UserService, JwtService]
})
export class UserModule {}

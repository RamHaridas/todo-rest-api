import { IsNotEmpty, MinLength } from "class-validator";

export class CreateTodoDto{

    @IsNotEmpty()
    @MinLength(6)
    note:string;
}
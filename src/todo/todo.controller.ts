import { Body, Controller, Delete, Get, Param, ParseIntPipe, Post, Patch, UsePipes, ValidationPipe, UseGuards } from '@nestjs/common';
import { TodoService } from './todo.service';
import { CreateTodoDto } from './dto/create-todo.dto';
import { AuthGuard } from 'src/auth/auth.guard';

@Controller('todo')
export class TodoController {

    constructor(private readonly todoService: TodoService){}

    @UseGuards(AuthGuard)
    @Post('create')
    @UsePipes(ValidationPipe)
    createTodoItem(@Body() createTodoDto: CreateTodoDto){
        return this.todoService.createTodoItem(createTodoDto);
    }

    @UseGuards(AuthGuard)
    @Patch('update/:id')
    @UsePipes(ValidationPipe)
    updateTodoItem(@Param('id', ParseIntPipe) id: number, @Body() createTodoDto: CreateTodoDto){
        return this.todoService.updateTodoItem(id, createTodoDto);
    }

    @UseGuards(AuthGuard)
    @Get()
    getTodoItems(){
        return this.todoService.getTodoItems()
    }

    @UseGuards(AuthGuard)
    @Get('id/:id')
      findTodoItemById(@Param('id', ParseIntPipe) id: number) {
        return this.todoService.findById(id);
    }

    @UseGuards(AuthGuard)
    @Delete('/:id')
    deleteById(@Param('id', ParseIntPipe) id: number){
        return this.todoService.deleteTodoItemById(id);
    }
}

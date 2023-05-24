import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Todo } from 'src/typeorm';
import { Repository } from 'typeorm';
import { CreateTodoDto } from './dto/create-todo.dto';

@Injectable()
export class TodoService {
    constructor(
        @InjectRepository(Todo) private readonly todoRepository: Repository<Todo>
    ){}

    createTodoItem(createTodoDto: CreateTodoDto){
        const newTodo = this.todoRepository.create(createTodoDto);
        return this.todoRepository.save(newTodo);
    }

    findById(id: number){
        return this.todoRepository.findOneBy({id});
    }

    getTodoItems(){
        return this.todoRepository.find();
    }

    deleteTodoItemById(id: number){
        return this.todoRepository.delete(id)
    }

    async updateTodoItem(id:number, todoItem: CreateTodoDto){
        const databaseResponse = await this.todoRepository.query(
            `
            UPDATE todo
            SET note = $2
            WHERE todo_id = $1
          `,
            [id, todoItem.note],
          );
          const entity = databaseResponse;
          if (!entity) {
            throw {"message":"Not found"}
          }
          return {"message":"Updated!"};
    }
}

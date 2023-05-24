import { Column, Entity, PrimaryGeneratedColumn, CreateDateColumn, UpdateDateColumn } from 'typeorm'

@Entity()
export class Todo {
    @PrimaryGeneratedColumn({
        type:'bigint',
        name:'todo_id'
    })
    id: number;

    @Column({
        nullable: false,
    })
    note: string;

    @CreateDateColumn()
    created_at: Date;

    @UpdateDateColumn()
    updated_at: Date;
}
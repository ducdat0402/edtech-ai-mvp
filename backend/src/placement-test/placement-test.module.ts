import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PlacementTestService } from './placement-test.service';
import { PlacementTestController } from './placement-test.controller';
import { PlacementTest } from './entities/placement-test.entity';
import { Question } from './entities/question.entity';
import { UsersModule } from '../users/users.module';
import { SubjectsModule } from '../subjects/subjects.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([PlacementTest, Question]),
    UsersModule,
    SubjectsModule,
  ],
  controllers: [PlacementTestController],
  providers: [PlacementTestService],
  exports: [PlacementTestService],
})
export class PlacementTestModule {}

